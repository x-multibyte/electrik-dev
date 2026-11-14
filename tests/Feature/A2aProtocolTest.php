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

it('fails closed in production when A2A server API key is not configured', function () {
    config(['services.adk.server_api_key' => '']);

    $previousEnv = app()->environment();
    app()->detectEnvironment(static fn (): string => 'production');

    try {
        $response = $this->postJson('/api/a2a/tasks/send', [
            'id' => 'task-prod-nokey',
            'message' => [
                'role' => 'user',
                'parts' => [['text' => 'Check status']],
            ],
        ], [
            'X-Electrik-Team-Id' => '10',
        ]);

        $response->assertStatus(503)
            ->assertJsonPath('status', 'failed')
            ->assertJsonPath('error.code', 'A2A_AUTH_NOT_CONFIGURED');
    } finally {
        app()->detectEnvironment(static fn (): string => (string) $previousEnv);
    }
});

it('rejects non-numeric team_id strings and header vs metadata team_id mismatches', function () {
    config(['services.adk.server_api_key' => 'secret-a2a-token']);

    $malformed = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-bad-int',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Check status']],
        ],
    ], [
        'X-Electrik-Team-Id' => '10abc',
        'X-A2A-Api-Key' => 'secret-a2a-token',
    ]);

    $malformed->assertStatus(422)
        ->assertJsonPath('error.code', 'MISSING_TENANT_CONTEXT');

    $mismatched = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-mismatch',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Check status']],
        ],
        'metadata' => [
            'team_id' => 99,
        ],
    ], [
        'X-Electrik-Team-Id' => '10',
        'X-A2A-Api-Key' => 'secret-a2a-token',
    ]);

    $mismatched->assertStatus(422)
        ->assertJsonPath('error.code', 'TENANT_CONTEXT_MISMATCH');
});

it('throws RuntimeException when RemoteAdkAgentTool receives an A2A failed envelope and handles null endpoint config', function () {
    config(['services.adk.endpoint' => null]);

    Http::fake([
        'http://127.0.0.1:8080/a2a/tasks/send' => Http::response([
            'id' => 'task-err',
            'status' => 'failed',
            'error' => ['message' => 'Tenant quota exceeded'],
        ], 200),
    ]);

    $tool = new RemoteAdkAgentTool(teamId: 42);

    expect(fn () => $tool->handle(new ToolRequest([
        'task_prompt' => 'Run heavy report',
    ])))->toThrow(RuntimeException::class, 'Tenant quota exceeded');
});

it('documents canonical A2A headers and endpoints in adk-a2a-bridge skill', function () {
    $skill = (string) file_get_contents(base_path('.agents/skills/adk-a2a-bridge/SKILL.md'));

    expect($skill)
        ->toContain('X-Electrik-Team-Id')
        ->toContain('metadata.team_id')
        ->toContain('X-A2A-Api-Key')
        ->toContain('/api/a2a/tasks/send')
        ->not->toContain('X-Tenant'.'-ID')
        ->not->toContain('metadata.tenant'.'_id');
});
