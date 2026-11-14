<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;
use RuntimeException;
use Stringable;

final class RemoteAdkAgentTool implements Tool
{
    public function __construct(
        private readonly int $teamId,
        private readonly ?string $endpoint = null,
        private readonly ?string $apiKey = null,
    ) {}

    /**
     * Describe the A2A remote delegation capability for the host model.
     */
    public function description(): Stringable|string
    {
        return 'Delegate multi-step analytics or workflow synthesis to the tenant-scoped Google ADK 2.0 A2A service.';
    }

    /**
     * Execute an outbound A2A task request carrying Electrik team isolation headers.
     */
    public function handle(Request $request): Stringable|string
    {
        $configuredEndpoint = config('services.adk.endpoint');
        $defaultEndpoint = is_string($configuredEndpoint) && $configuredEndpoint !== ''
            ? $configuredEndpoint
            : 'http://127.0.0.1:8080/a2a/tasks/send';
        $endpoint = ($this->endpoint !== null && $this->endpoint !== '') ? $this->endpoint : $defaultEndpoint;
        $apiKey = $this->apiKey ?? (string) config('services.adk.api_key', '');
        $taskPrompt = (string) ($request['task_prompt'] ?? '');
        $skillHint = (string) ($request['skill_hint'] ?? '');

        $headers = [
            'X-Electrik-Team-Id' => (string) $this->teamId,
            'Accept' => 'application/json',
        ];

        if ($apiKey !== '') {
            $headers['X-A2A-Api-Key'] = $apiKey;
        }

        $metadata = ['team_id' => $this->teamId];
        if ($skillHint !== '') {
            $metadata['skill_hint'] = $skillHint;
        }

        $response = Http::timeout(30)
            ->withHeaders($headers)
            ->post($endpoint, [
                'id' => (string) Str::uuid(),
                'message' => [
                    'role' => 'user',
                    'parts' => [
                        ['text' => $taskPrompt],
                    ],
                ],
                'metadata' => $metadata,
            ]);

        if ($response->failed()) {
            throw new RuntimeException("Remote ADK A2A request failed with HTTP {$response->status()}.");
        }

        $data = $response->json();
        if (data_get($data, 'status') === 'failed') {
            $errorMessage = (string) data_get($data, 'error.message', 'Unknown A2A error');
            throw new RuntimeException("A2A agent execution failed: {$errorMessage}");
        }

        return (string) data_get($data, 'message.parts.0.text', '');
    }

    /**
     * Define the JSON schema contract for invoking the remote ADK agent tool.
     *
     * @return array<string, mixed>
     */
    public function schema(JsonSchema $schema): array
    {
        return [
            'task_prompt' => $schema->string()->description('Task instruction for the Google ADK agent.')->required(),
            'skill_hint' => $schema->string()->description('Optional Electrik workspace skill name.'),
        ];
    }
}
