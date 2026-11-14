<?php

declare(strict_types=1);

namespace App\Ai;

use InvalidArgumentException;
use RuntimeException;

final class SkillRegistry
{
    /** @var array<string, string> */
    private array $paths = [];

    /**
     * Register a named workspace skill markdown file path.
     */
    public function register(string $name, string $path): void
    {
        $this->paths[$name] = $path;
    }

    /**
     * Load a registered skill's markdown body without YAML frontmatter.
     */
    public function load(string $name): string
    {
        if (! isset($this->paths[$name])) {
            throw new InvalidArgumentException("AI skill [{$name}] is not registered.");
        }

        $path = $this->paths[$name];
        if (! is_file($path)) {
            throw new RuntimeException("AI skill file not found at [{$path}].");
        }

        $contents = (string) file_get_contents($path);

        return (string) preg_replace('/^---\s*\n.*?\n---\s*\n/s', '', $contents);
    }
}
