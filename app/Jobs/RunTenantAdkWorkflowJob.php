<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Ai\SkillRegistry;
use Electrik\Models\Team;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

final class RunTenantAdkWorkflowJob implements ShouldQueue
{
    use Queueable;

    public function __construct(
        public readonly int $teamId,
        public readonly string $sessionId,
        public readonly string $prompt,
        public readonly string $skillName = 'electrik-cashier-billing',
    ) {}

    /**
     * Dispatch the skill-enriched A2A task and report Cashier metered usage on the team.
     */
    public function handle(SkillRegistry $registry): void
    {
        $skillInstructions = $registry->load($this->skillName);
        $configuredEndpoint = config('services.adk.endpoint');
        $endpoint = is_string($configuredEndpoint) && $configuredEndpoint !== ''
            ? $configuredEndpoint
            : 'http://127.0.0.1:8080/a2a/tasks/send';
        $apiKey = (string) config('services.adk.api_key', '');

        $headers = [
            'X-Electrik-Team-Id' => (string) $this->teamId,
            'Accept' => 'application/json',
        ];

        if ($apiKey !== '') {
            $headers['X-A2A-Api-Key'] = $apiKey;
        }

        $response = Http::timeout(60)
            ->withHeaders($headers)
            ->post($endpoint, [
                'id' => $this->sessionId,
                'message' => [
                    'role' => 'user',
                    'parts' => [
                        ['text' => "{$skillInstructions}\n\nUser Task:\n{$this->prompt}"],
                    ],
                ],
                'metadata' => [
                    'team_id' => $this->teamId,
                    'skill' => $this->skillName,
                ],
            ]);

        if ($response->failed()) {
            throw new RuntimeException("ADK workflow job [{$this->sessionId}] failed with HTTP {$response->status()}.");
        }

        $data = $response->json();
        if (data_get($data, 'status') === 'failed') {
            $errorMessage = (string) data_get($data, 'error.message', 'Unknown A2A error');
            throw new RuntimeException("ADK workflow job [{$this->sessionId}] failed: {$errorMessage}");
        }

        $totalTokens = (int) data_get($data, 'metadata.usage.total_tokens', 0);
        if ($totalTokens > 0 && class_exists(Team::class) && Schema::hasTable((new Team)->getTable())) {
            $team = Team::query()->find($this->teamId);
            if ($team !== null && (! method_exists($team, 'hasStripeId') || $team->hasStripeId())) {
                if (method_exists($team, 'reportMeterEvent')) {
                    $team->reportMeterEvent('ai_workflow_tokens', quantity: $totalTokens);
                } else {
                    $team->subscription('default')?->reportUsage($totalTokens);
                }
            }
        }
    }
}
