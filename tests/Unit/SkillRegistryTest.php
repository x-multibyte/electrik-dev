<?php

declare(strict_types=1);

use App\Ai\SkillRegistry;
use Tests\TestCase;

uses(TestCase::class);

it('loads registered skill markdown and strips YAML frontmatter at runtime', function () {
    $registry = new SkillRegistry;
    $registry->register(
        'adk-a2a-bridge',
        base_path('.agents/skills/adk-a2a-bridge/SKILL.md'),
    );

    $instructions = $registry->load('adk-a2a-bridge');

    expect($instructions)
        ->not->toContain('name: adk-a2a-bridge')
        ->toContain('# Laravel AI SDK & Google ADK 2.0 Bridge Skill');
});

it('throws InvalidArgumentException when loading an unregistered skill', function () {
    $registry = new SkillRegistry;
    $registry->load('non-existent-skill');
})->throws(InvalidArgumentException::class);
