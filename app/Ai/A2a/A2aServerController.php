<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use App\Ai\Agents\TenantCopilotAgent;
use App\Ai\SkillRegistry;
use Electrik\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

final class A2aServerController // @pest-arch-ignore-line
{
    /**
     * Serve the A2A agent discovery metadata card.
     */
    public function agentCard(): JsonResponse
    {
        return response()->json([
            '$schema' => 'https://a2a-protocol.org/schemas/v1/agent.json',
            'name' => config('app.name', 'ElectrikSaaS').'-agent',
            'description' => 'Multi-tenant Electrik Laravel SaaS Agent with Cashier billing and tenant scoping.',
            'version' => '1.0.0',
            'endpoint' => url('/api/a2a/tasks/send'),
            'capabilities' => [
                'streaming' => false,
                'stateful' => true,
                'pushNotifications' => false,
            ],
            'authentication' => [
                'type' => 'apiKey',
                'header' => 'X-A2A-Api-Key',
            ],
            'skills' => [
                [
                    'name' => 'tenant-query',
                    'description' => 'Execute team-scoped tenant queries and inspect tenant state.',
                    'tags' => ['electrik', 'saas', 'multi-tenant'],
                ],
                [
                    'name' => 'cashier-billing-status',
                    'description' => 'Verify team Stripe subscription and metered token balance.',
                    'tags' => ['billing', 'stripe', 'cashier'],
                ],
            ],
        ]);
    }

    /**
     * Execute an incoming tenant-scoped A2A task request.
     */
    public function handleTask(Request $request): JsonResponse
    {
        $expectedKey = (string) config('services.adk.server_api_key', '');
        if (! app()->environment(['local', 'testing']) && $expectedKey === '') {
            return response()->json([
                'id' => (string) $request->input('id', ''),
                'status' => 'failed',
                'error' => [
                    'code' => 'A2A_AUTH_NOT_CONFIGURED',
                    'message' => 'A2A server API key must be configured outside local/testing environments.',
                ],
            ], 503);
        }

        if ($expectedKey !== '' && ! hash_equals($expectedKey, (string) $request->header('X-A2A-Api-Key', ''))) {
            return response()->json([
                'id' => (string) $request->input('id', ''),
                'status' => 'failed',
                'error' => [
                    'code' => 'INVALID_A2A_API_KEY',
                    'message' => 'Invalid or missing X-A2A-Api-Key header.',
                ],
            ], 401);
        }

        $validated = $request->validate([
            'id' => ['required', 'string'],
            'message.role' => ['required', 'string'],
            'message.parts' => ['required', 'array', 'min:1'],
            'message.parts.*.text' => ['required', 'string'],
            'metadata' => ['nullable', 'array'],
        ]);

        $rawHeaderTeam = $request->header('X-Electrik-Team-Id');
        $rawMetaTeam = data_get($validated, 'metadata.team_id');
        $hasHeaderTeam = $rawHeaderTeam !== null && $rawHeaderTeam !== '';
        $hasMetaTeam = $rawMetaTeam !== null && $rawMetaTeam !== '';

        $headerTeamId = $hasHeaderTeam ? $this->parsePositiveTeamId($rawHeaderTeam) : null;
        $metaTeamId = $hasMetaTeam ? $this->parsePositiveTeamId($rawMetaTeam) : null;

        if (($hasHeaderTeam && $headerTeamId === null) || ($hasMetaTeam && $metaTeamId === null)) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid positive integer X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        if ($headerTeamId !== null && $metaTeamId !== null && $headerTeamId !== $metaTeamId) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'TENANT_CONTEXT_MISMATCH',
                    'message' => 'X-Electrik-Team-Id header does not match metadata.team_id.',
                ],
            ], 422);
        }

        $teamId = $headerTeamId ?? $metaTeamId;
        if ($teamId === null) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        if (class_exists(Team::class) && ! Team::query()->whereKey($teamId)->exists()) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'TEAM_NOT_FOUND',
                    'message' => 'Specified Electrik team context does not exist.',
                ],
            ], 404);
        }

        $requestedSkill = (string) (data_get($validated, 'metadata.skill_hint')
            ?? data_get($validated, 'metadata.skill')
            ?? 'adk-a2a-bridge');

        /** @var SkillRegistry $registry */
        $registry = app(SkillRegistry::class);
        $skillName = $requestedSkill !== '' && $registry->has($requestedSkill)
            ? $requestedSkill
            : 'adk-a2a-bridge';

        $userPrompt = (string) data_get($validated, 'message.parts.0.text', '');
        Log::info('A2A Task received', ['id' => $validated['id'], 'team_id' => $teamId, 'skill' => $skillName]);

        $agent = new TenantCopilotAgent($teamId, $skillName);
        $agentResponse = (string) $agent->prompt($userPrompt);

        return response()->json([
            'id' => $validated['id'],
            'status' => 'completed',
            'message' => [
                'role' => 'assistant',
                'parts' => [
                    ['text' => $agentResponse],
                ],
            ],
            'metadata' => [
                'team_id' => $teamId,
                'skill' => $skillName,
                'processed_at' => now()->toISOString(),
            ],
        ]);
    }

    private function parsePositiveTeamId(mixed $value): ?int
    {
        if (is_bool($value) || (! is_int($value) && ! is_string($value))) {
            return null;
        }

        if (is_string($value) && ! preg_match('/^[1-9]\d*$/', $value)) {
            return null;
        }

        $parsed = filter_var($value, FILTER_VALIDATE_INT, [
            'options' => ['min_range' => 1],
        ]);

        return $parsed === false ? null : $parsed;
    }
}
