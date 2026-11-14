<?php

declare(strict_types=1);

it('enforces Antigravity CLI sandbox and monotonic deny rules in .gemini/settings.json', function () {
    $path = base_path('.gemini/settings.json');
    expect(is_file($path))->toBeTrue();

    $settings = json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);

    expect($settings['enableTerminalSandbox'])->toBeTrue()
        ->and($settings['agentMode'])->toBe('accept-edits')
        ->and($settings['permissions']['deny'])->toContain(
            'write_file(.env)',
            'write_file(vendor/)',
            'write_file(bootstrap/app.php)',
            'write_file(app/Services/)',
            'write_file(app/Repositories/)',
            'write_file(app/Actions/)',
        )
        ->and($settings['permissions']['allow'])->toContain(
            'mcp(laravel-boost/database-schema)',
            'mcp(laravel-boost/search-docs)',
            'mcp(electrik-slate/*)',
        );
});

it('registers laravel-boost and electrik-slate MCP servers in .agents/mcp_config.json', function () {
    $path = base_path('.agents/mcp_config.json');
    expect(is_file($path))->toBeTrue();

    $mcp = json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);

    expect($mcp['mcpServers'])->toHaveKeys(['laravel-boost', 'electrik-slate'])
        ->and($mcp['mcpServers']['laravel-boost']['args'])->toBe(['artisan', 'boost:mcp'])
        ->and($mcp['mcpServers']['electrik-slate']['args'])->toBe(['-y', '@electrik/slate-mcp']);
});

it('declares Electrik and Slate llms.txt endpoints and Boost block in AGENTS.md', function () {
    $path = base_path('AGENTS.md');
    expect(is_file($path))->toBeTrue();

    $content = (string) file_get_contents($path);
    expect($content)
        ->toContain('https://electrik.dev/llms.txt')
        ->toContain('https://slate.electrik.dev/llms.txt')
        ->toContain('<laravel-boost-guidelines>');
});

it('defines path-scoped Laravel Boost project rules in .ai/rules', function () {
    $index = base_path('.ai/rules/index.md');
    expect(is_file($index))->toBeTrue();

    $ruleFiles = [
        'electrik-package-boundary.md',
        'team-tenancy-models.md',
        'slate-livewire-views.md',
        'controllers-and-requests.md',
    ];

    foreach ($ruleFiles as $file) {
        $fullPath = base_path(".ai/rules/{$file}");
        expect(is_file($fullPath))->toBeTrue();
        expect((string) file_get_contents($fullPath))->toContain('paths:');
    }
});
