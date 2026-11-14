<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Ai\SkillRegistry;
use Electrik\Models\Team;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
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
        $endpoint = (string) config('services.adk.endpoint', 'http://127.0.0.1:8080/a2a/tasks/send');
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

        $totalTokens = (int) data_get($response->json(), 'metadata.usage.total_tokens', 0);
        if ($totalTokens > 0 && class_exists(Team::class)) {
            $team = Team::query()->find($this->teamId);
            $team?->subscription('default')?->reportUsage($totalTokens);
        }
    }
}
