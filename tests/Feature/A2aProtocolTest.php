<?php

declare(strict_types=1);

it('serves the A2A agent card at /.well-known/agent.json', function () {
    $response = $this->getJson('/.well-known/agent.json');

    $response->assertOk()
        ->assertJsonPath('$schema', 'https://a2a-protocol.org/schemas/v1/agent.json')
        ->assertJsonStructure([
            'name',
            'description',
            'version',
            'endpoint',
            'capabilities' => ['streaming', 'stateful'],
            'skills' => [
                '*' => ['name', 'description', 'tags'],
            ],
        ]);
});

it('rejects A2A task without team context with HTTP 422', function () {
    $response = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-missing-team',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Check billing status']],
        ],
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('status', 'failed')
        ->assertJsonPath('error.code', 'MISSING_TENANT_CONTEXT');
});

it('rejects A2A task with invalid X-A2A-Api-Key when services.adk.server_api_key is configured', function () {
    config(['services.adk.server_api_key' => 'secret-a2a-token']);

    $response = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-unauth',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Check billing status']],
        ],
    ], [
        'X-Electrik-Team-Id' => '10',
        'X-A2A-Api-Key' => 'wrong-token',
    ]);

    $response->assertStatus(401)
        ->assertJsonPath('error.code', 'INVALID_A2A_API_KEY');
});

it('completes a valid tenant-scoped A2A task when authenticated', function () {
    config(['services.adk.server_api_key' => 'secret-a2a-token']);

    $response = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-valid-10',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Summarize billing status']],
        ],
    ], [
        'X-Electrik-Team-Id' => '10',
        'X-A2A-Api-Key' => 'secret-a2a-token',
    ]);

    $response->assertOk()
        ->assertJsonPath('id', 'task-valid-10')
        ->assertJsonPath('status', 'completed')
        ->assertJsonPath('metadata.team_id', 10)
        ->assertJsonStructure([
            'message' => ['role', 'parts' => [['text']]],
            'metadata' => ['team_id', 'processed_at'],
        ]);
});

use App\Ai\A2a\RemoteAdkAgentTool;
use App\Ai\SkillRegistry;
use App\Jobs\RunTenantAdkWorkflowJob;
use Illuminate\Http\Client\Request as HttpClientRequest;
use Illuminate\Support\Facades\Http;
use Laravel\Ai\Tools\Request as ToolRequest;

it('dispatches task to remote ADK agent via RemoteAdkAgentTool with tenant headers', function () {
    Http::fake([
        'http://127.0.0.1:8080/a2a/tasks/send' => Http::response([
            'id' => 'task-mock-id',
            'status' => 'completed',
            'message' => [
                'role' => 'assistant',
                'parts' => [['text' => 'Synthesized response from ADK multi-agent cluster.']],
            ],
        ]),
    ]);

    $tool = new RemoteAdkAgentTool(
        teamId: 42,
        endpoint: 'http://127.0.0.1:8080/a2a/tasks/send',
        apiKey: 'outbound-adk-key',
    );

    $result = $tool->handle(new ToolRequest([
        'task_prompt' => 'Analyze tenant usage',
        'skill_hint' => 'electrik-cashier-billing',
    ]));

    expect((string) $result)->toBe('Synthesized response from ADK multi-agent cluster.');

    Http::assertSent(function (HttpClientRequest $request) {
        return $request->hasHeader('X-Electrik-Team-Id', '42')
            && $request->hasHeader('X-A2A-Api-Key', 'outbound-adk-key')
            && data_get($request->data(), 'metadata.skill_hint') === 'electrik-cashier-billing';
    });
});

it('executes RunTenantAdkWorkflowJob by injecting SkillRegistry instructions into the A2A payload', function () {
    Http::fake([
        'http://127.0.0.1:8080/a2a/tasks/send' => Http::response([
            'id' => 'session-99',
            'status' => 'completed',
            'message' => [
                'role' => 'assistant',
                'parts' => [['text' => 'Job completed']],
            ],
            'metadata' => [
                'usage' => ['total_tokens' => 350],
            ],
        ]),
    ]);

    $job = new RunTenantAdkWorkflowJob(
        teamId: 7,
        sessionId: 'session-99',
        prompt: 'Audit team invoices',
        skillName: 'electrik-cashier-billing',
    );

    $job->handle(app(SkillRegistry::class));

    Http::assertSent(function (HttpClientRequest $request) {
        $sentText = (string) data_get($request->data(), 'message.parts.0.text', '');

        return $request->hasHeader('X-Electrik-Team-Id', '7')
            && str_contains($sentText, 'Electrik Team-Scoped Stripe Cashier Billing Skill')
            && str_contains($sentText, 'Audit team invoices');
    });
});
