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
