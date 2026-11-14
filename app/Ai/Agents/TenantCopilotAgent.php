<?php

declare(strict_types=1);

namespace App\Ai\Agents;

use App\Ai\A2a\RemoteAdkAgentTool;
use App\Ai\SkillRegistry;
use Laravel\Ai\Attributes\MaxSteps;
use Laravel\Ai\Attributes\Model;
use Laravel\Ai\Attributes\Provider;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\HasTools;
use Laravel\Ai\Enums\Lab;
use Laravel\Ai\Promptable;
use Stringable;

#[Provider(Lab::Gemini)]
#[Model('gemini-2.5-flash')]
#[MaxSteps(6)]
final class TenantCopilotAgent implements Agent, HasTools
{
    use Promptable;

    public function __construct(
        public readonly int $teamId,
        public readonly string $skillName = 'adk-a2a-bridge',
    ) {}

    /**
     * Build tenant-scoped instructions from the registered workspace skill.
     */
    public function instructions(): Stringable|string
    {
        $registry = app(SkillRegistry::class);

        return "You are the tenant-scoped Electrik SaaS Copilot for Team ID {$this->teamId}.\n\n"
            .$registry->load($this->skillName);
    }

    /**
     * Expose outbound ADK A2A workflow delegation tools for this tenant.
     */
    public function tools(): iterable
    {
        return [
            new RemoteAdkAgentTool(teamId: $this->teamId),
        ];
    }
}
