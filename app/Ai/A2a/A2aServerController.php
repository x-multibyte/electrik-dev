<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use App\Ai\Agents\TenantCopilotAgent;
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

        $teamId = (int) ($request->header('X-Electrik-Team-Id') ?? data_get($validated, 'metadata.team_id', 0));
        if ($teamId <= 0) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        $userPrompt = (string) data_get($validated, 'message.parts.0.text', '');
        Log::info('A2A Task received', ['id' => $validated['id'], 'team_id' => $teamId]);

        $agent = new TenantCopilotAgent($teamId);
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
                'processed_at' => now()->toISOString(),
            ],
        ]);
    }
}
