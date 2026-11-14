#!/usr/bin/env bash
# ==============================================================================
# Electrik Laravel 13 SaaS × Google Antigravity 2.0 & CLI × Laravel Boost × ADK
# 一键工程化配置与双向 A2A 协议资产生成脚本 (setup_electrik_agent_kit.sh)
# ==============================================================================
set -euo pipefail

echo "[1/8] 创建 Antigravity CLI, Laravel Boost, A2A 与 Google ADK 目录拓扑..."
mkdir -p .gemini
mkdir -p .agents/bin
mkdir -p .agents/skills/electrik-tenant-scaffold
mkdir -p .agents/skills/slate-blade-ui
mkdir -p .agents/skills/electrik-cashier-billing
mkdir -p .agents/skills/laravel-pest-verify
mkdir -p .agents/skills/laravel-pint-fix
mkdir -p .agents/skills/laravel-migration-validator/scripts
mkdir -p .agents/skills/adk-a2a-bridge
mkdir -p .ai/rules
mkdir -p .ai/guidelines
mkdir -p .ai/skills
mkdir -p app/Ai/A2a
mkdir -p app/Ai/Agents
mkdir -p app/Jobs
mkdir -p routes
mkdir -p tests/Feature
mkdir -p adk_service

echo "[2/8] 写入 AGENTS.md 顶层机器指令宪章..."
cat << 'EOF' > AGENTS.md
# Electrik Laravel 13 SaaS — AI Agent Engineering Constitution

## 1. Authoritative Machine-Readable Documentation Endpoints
Before planning routes, UI views, billing flows, or domain models, consult these canonical LLM indexes:
- Electrik Core Index: https://electrik.dev/llms.txt
- Electrik Full Reference: https://electrik.dev/llms-full.txt
- Electrik AI & Agents Guide: https://electrik.dev/docs/getting-started/ai
- Electrik Slate 3 UI Index: https://slate.electrik.dev/llms.txt
- Electrik Slate 3 Full Dump: https://slate.electrik.dev/llms-full.txt
- Electrik Slate MCP Guide: https://slate.electrik.dev/docs/ai
- Google ADK 2.0 Guide: https://adk.dev/2.0/
- Agent2Agent (A2A) Protocol: https://github.com/google-a2a/a2a-python

## 2. Non-Negotiable Architectural Invariants
1. **Package Encapsulation (`Electrik\` vs `App\`)**:
   - Auth, teams, Stripe Cashier billing, onboarding, `/ops` operator console, and account settings live inside `vendor/electrik/electrik` under the `Electrik\` namespace.
   - NEVER copy or fork `Electrik\` controllers, Livewire components, or views into `App\` unless explicitly instructed to override a specific published view.
   - Customize shell behavior through `config/electrik.php` and `ELECTRIK_*` environment flags.
2. **Team-as-Tenant Boundary (`BelongsToTeam`)**:
   - The `Team` model is the primary boundary for multi-tenancy, Spatie permissions, and Laravel Cashier subscriptions.
   - ALWAYS generate new tenant-scoped models and resources via `php artisan electrik:make:model <Name>` or `php artisan electrik:make:resource <Name>` (use `--no-team` ONLY for global system entities).
   - Every tenant model MUST use the `BelongsToTeam` trait and scope all queries to the authenticated user's current team.
3. **UI System (`<x-slate::*>` & Livewire 4)**:
   - Use anonymous Blade components from Electrik Slate 3 (`<x-slate::*>`) and marketing sections from `<x-slate-block::*>`.
   - Style exclusively with Tailwind CSS v4 tokens (`--slate-primary`, `--slate-background`, etc.) and built-in dark mode pairs.
   - NEVER introduce React, Vue, Inertia, Flux UI, or shadcn/ui trees into an Electrik application.
4. **Laravel 13 & PHP 8.4+ Cohesion**:
   - Maintain Laravel 13's single-entry `bootstrap/app.php` structure. NEVER recreate `app/Http/Kernel.php` or `app/Console/Kernel.php`.
   - NEVER create unapproved abstraction directories (`app/Services/`, `app/Repositories/`, `app/Actions/`). Keep domain logic in Eloquent Models, FormRequests, Policies, Queued Jobs, and Livewire Components.
   - Use PHP 8.4 Property Hooks and Asymmetric Visibility (`public private(set)`) where appropriate, and use `casts(): array` method instead of `$casts` property on models.
5. **Micro-Transaction Workflow in Antigravity 2.0 & CLI**:
   - Follow Contract-Driven Development: write or update the Pest test first -> run `vendor/bin/pest` (Red) -> implement minimal code -> run `vendor/bin/pest` (Green) -> run `vendor/bin/pint --dirty --format agent` -> commit snapshot -> run `/clear` in Antigravity CLI to reset context.
   - If architectural drift occurs, do not argue in chat; immediately `git checkout -- .` or `git reset` and restart from a clean `/clear` session.

<laravel-boost-guidelines>
<!-- Managed automatically by `php artisan boost:install` and `php artisan boost:update` -->
</laravel-boost-guidelines>
EOF

echo "[3/8] 写入 .gemini/settings.json 权限防火墙与 .agents/mcp_config.json..."
cat << 'EOF' > .gemini/settings.json
{
  "$schema": "https://antigravity.google/schemas/v1/settings.json",
  "agentMode": "accept-edits",
  "enableTerminalSandbox": true,
  "statusLine": {
    "type": "command",
    "command": ".agents/bin/statusline.sh"
  },
  "permissions": {
    "allow": [
      "mcp(laravel-boost/application-info)",
      "mcp(laravel-boost/database-connections)",
      "mcp(laravel-boost/database-schema)",
      "mcp(laravel-boost/database-query)",
      "mcp(laravel-boost/get-absolute-url)",
      "mcp(laravel-boost/last-error)",
      "mcp(laravel-boost/read-log-entries)",
      "mcp(laravel-boost/browser-logs)",
      "mcp(laravel-boost/search-docs)",
      "mcp(laravel-boost/record-rule)",
      "mcp(electrik-slate/*)",
      "read_url(https://electrik.dev/*)",
      "read_url(https://slate.electrik.dev/*)",
      "read_url(https://laravel.com/docs/*)",
      "read_url(https://laravel.com/framework/docs/*)",
      "read_url(https://adk.dev/*)",
      "read_url(https://github.com/google-a2a/*)",
      "command(regex:vendor/bin/pest.*)",
      "command(regex:php artisan test.*)",
      "command(regex:vendor/bin/pint.*)",
      "command(php artisan route:list)",
      "command(php artisan config:show)",
      "command(php artisan env)",
      "command(php artisan list)",
      "command(php artisan about)",
      "command(php artisan model:show)",
      "command(php artisan migrate:status)",
      "command(regex:php artisan optimize:clear.*)",
      "command(regex:php artisan (config|route|view|event):clear)",
      "command(regex:php artisan electrik:make:(model|resource) [a-zA-Z0-9_/]+( --[a-zA-Z0-9_-]+)*)",
      "command(regex:php artisan make:(model|controller|migration|resource|request|test|component|livewire|event|listener|job|policy|rule|cast|agent) [a-zA-Z0-9_/]+( --[a-zA-Z0-9_-]+)*)",
      "command(regex:php artisan boost:update.*)",
      "command(regex:python3 \\.agents/skills/laravel-migration-validator/scripts/validate_migration\\.py.*)",
      "command(regex:composer (show|dump-autoload|check-platform-reqs).*)",
      "command(regex:git (status|diff|log|branch|add|commit).*)",
      "read_file(AGENTS.md)",
      "read_file(.ai/)",
      "read_file(.agents/)",
      "read_file(app/)",
      "read_file(bootstrap/)",
      "read_file(config/)",
      "read_file(database/)",
      "read_file(public/)",
      "read_file(resources/)",
      "read_file(routes/)",
      "read_file(tests/)",
      "read_file(vendor/electrik/)",
      "read_file(adk_service/)",
      "write_file(.ai/rules/)",
      "write_file(.ai/guidelines/)",
      "write_file(.ai/skills/)",
      "write_file(.agents/skills/)",
      "write_file(app/Ai/)",
      "write_file(app/Http/Controllers/)",
      "write_file(app/Http/Requests/)",
      "write_file(app/Http/Resources/)",
      "write_file(app/Livewire/)",
      "write_file(app/Models/)",
      "write_file(app/Policies/)",
      "write_file(app/Providers/)",
      "write_file(app/Rules/)",
      "write_file(app/Jobs/)",
      "write_file(app/Events/)",
      "write_file(app/Listeners/)",
      "write_file(database/factories/)",
      "write_file(database/migrations/)",
      "write_file(database/seeders/)",
      "write_file(resources/views/)",
      "write_file(routes/)",
      "write_file(tests/Feature/)",
      "write_file(tests/Unit/)",
      "write_file(adk_service/)"
    ],
    "deny": [
      "command(regex:php artisan (migrate:fresh|migrate:reset|db:wipe|key:generate).*)",
      "command(regex:git (push --force|reset --hard|clean -fd).*)",
      "command(sudo)",
      "command(regex:curl .*)",
      "command(regex:wget .*)",
      "command(rm -rf)",
      "write_file(.env)",
      "write_file(.env.*)",
      "write_file(.git/)",
      "write_file(vendor/)",
      "write_file(composer.json)",
      "write_file(composer.lock)",
      "write_file(package.json)",
      "write_file(package-lock.json)",
      "write_file(bootstrap/app.php)",
      "write_file(bootstrap/providers.php)",
      "write_file(app/Http/Kernel.php)",
      "write_file(app/Console/Kernel.php)",
      "write_file(app/Services/)",
      "write_file(app/Repositories/)",
      "write_file(app/Actions/)",
      "write_file(Services/)",
      "write_file(Repositories/)",
      "write_file(Actions/)",
      "read_file(/home/*/.ssh)",
      "read_file(/home/*/.gnupg)",
      "read_file(/etc/)"
    ],
    "ask": [
      "mcp(laravel-boost/tinker)",
      "command(php artisan migrate)",
      "command(php artisan electrik:install)",
      "command(php artisan electrik:stripe:sync)",
      "command(php artisan electrik:seed-demo)",
      "command(regex:./scripts/reset-electrik-sandbox\\.sh.*)",
      "command(regex:composer (require|remove|update).*)",
      "command(regex:npm (install|run build|run dev).*)",
      "write_file(config/)"
    ]
  }
}
EOF

cat << 'EOF' > .agents/mcp_config.json
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"],
      "env": {
        "APP_ENV": "local"
      }
    },
    "electrik-slate": {
      "command": "npx",
      "args": ["-y", "@electrik/slate-mcp"]
    }
  }
}
EOF

cat << 'EOF' > .agents/bin/statusline.sh
#!/usr/bin/env bash
payload="$(cat)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"
printf "\033[1;36m[Electrik SaaS]\033[0m \033[1;32m⎇ %s\033[0m | Sandbox: ON | A2A: Enabled\n" "$branch"
EOF
chmod +x .agents/bin/statusline.sh

echo "[4/8] 写入 .ai/rules/ 项目级规则与 .ai/guidelines/..."
cat << 'EOF' > .ai/rules/index.md
# Project Rules Index

- `electrik-package-boundary.md` — Applies to `config/**`, `routes/**`, `app/Providers/**`: Enforces vendor isolation for `Electrik\` and configuration-driven customization.
- `team-tenancy-models.md` — Applies to `app/Models/**`, `database/migrations/**`: Enforces `BelongsToTeam` multi-tenancy, PHP 8.4 model conventions, and integer-cents currency storage.
- `slate-livewire-views.md` — Applies to `resources/views/**`, `app/Livewire/**`: Enforces Electrik Slate 3 `<x-slate::*>` anonymous components, Tailwind CSS v4 tokens, and Livewire 4 patterns.
- `controllers-and-requests.md` — Applies to `app/Http/**`: Enforces thin controllers, FormRequest validation, and team-scoped Spatie policy authorization.
EOF

cat << 'EOF' > .ai/rules/electrik-package-boundary.md
---
paths:
  - config/**
  - routes/**
  - app/Providers/**
---

# Electrik Package Encapsulation & Extension Rules

## Keep the SaaS Shell in Vendor
1. Never copy or recreate `Electrik\` routes (`/login`, `/register`, `/billing`, `/ops`, `/api/electrik/*`) inside `routes/web.php` or `routes/api.php`.
2. Toggle features (such as `ELECTRIK_SAMPLE_PROJECTS` or `ELECTRIK_OPERATOR_EMAILS`) via `config/electrik.php` and environment variables rather than modifying package service providers.
3. All monetary amounts across billing plans, add-ons, and custom usage ledgers must be stored and calculated as integer cents.
EOF

cat << 'EOF' > .ai/rules/team-tenancy-models.md
---
paths:
  - app/Models/**
  - database/migrations/**
---

# Multi-Tenant Team Scoping & Eloquent Conventions

## Mandatory `BelongsToTeam` Isolation
1. Every tenant-owned domain model in `app/Models/` must be scaffolded with `php artisan electrik:make:model` and use the `BelongsToTeam` trait.
2. Every corresponding migration table must include `$table->foreignId('team_id')->constrained()->cascadeOnDelete();` and index `team_id` alongside query filter columns.
3. Subscriptions and Cashier billing methods (`subscribed()`, `newSubscription()`, metered usage reporting) must be called on the active `Team` instance (`$user->currentTeam`), never on the `User` model.
4. Use Laravel 12/13 `protected function casts(): array` method instead of the deprecated `$casts` property, and prefer PHP 8.4 asymmetric visibility (`public private(set)`) for read-only domain properties.
EOF

cat << 'EOF' > .ai/rules/slate-livewire-views.md
---
paths:
  - resources/views/**
  - app/Livewire/**
---

# Electrik Slate 3 UI & Livewire 4 Rules

## Exclusive `<x-slate::*>` Component Usage
1. Build all UI views using anonymous Blade components from Electrik Slate 3 (`<x-slate::button>`, `<x-slate::card>`, `<x-slate::input>`, `<x-slate::dialog>`, `<x-slate::table>`, etc.) and `<x-slate-block::*>` for marketing sections.
2. Consult `https://slate.electrik.dev/llms-full.txt` or the `electrik-slate` MCP server before composing new forms, dialogs, or data tables.
3. Use Slate semantic CSS tokens (`--slate-primary`, `--slate-background`, `--slate-foreground`, `--slate-muted`) with Tailwind CSS v4 so built-in dark mode works automatically.
4. Bind forms with Livewire 4 `wire:model` and pass validation state natively through Slate form primitives; support RTL layouts (`ar`) and localized strings (`__()`) across all 5 supported locales (`en`, `es`, `fr`, `ar`, `hi`).
EOF

cat << 'EOF' > .ai/rules/controllers-and-requests.md
---
paths:
  - app/Http/**
---

# Controllers, Validation, and Authorization Rules

## Thin Controllers & Team-Scoped Policies
1. Controllers in `app/Http/Controllers/` may only perform Policy/Gate authorization, FormRequest validation, and Eloquent model or Queued Job dispatch.
2. Never write raw SQL queries, external HTTP calls, or multi-step business orchestration inside controllers; dispatch queued jobs (`ShouldQueue`) for slow external APIs or AI agent invocations.
3. Always verify Spatie team-scoped permissions (`$user->can(...)` within current team context) and Policy ownership before mutating any `BelongsToTeam` model.
EOF

cat << 'EOF' > .ai/guidelines/electrik-core.md
## Electrik SaaS Starter Kit & Slate 3 Guidelines

This application uses `electrik/electrik` (v5.5+ MIT) as its vendor-encapsulated SaaS shell and `electrik/slate` (v3.0+) for anonymous Blade UI primitives.

### Core Conventions
- **Team-Centric Multi-Tenancy**: Always use `php artisan electrik:make:model` so models include `BelongsToTeam`.
- **Team-Scoped Cashier Billing**: Subscriptions and metered usage belong to `Team`, not `User`.
- **Anonymous Slate Components**: Render UI with `<x-slate::*>` and `<x-slate-block::*>`. Do not install React, Vue, Inertia, or Flux UI.
- **A2A Protocol**: Inter-agent communication follows the A2A spec via `app/Ai/A2a/` and `adk_service/`.
EOF

echo "[5/8] 写入 7 个工作区专属 Skills 并建立 .ai/skills 软链接..."
cat << 'EOF' > .agents/skills/electrik-tenant-scaffold/SKILL.md
---
name: electrik-tenant-scaffold
description: Scaffold multi-tenant Eloquent models, resources, migrations, policies, and Spatie team permissions in an Electrik Laravel 13 SaaS project.
---

# Electrik Multi-Tenant Scaffold Skill

## When to Use
Activate this skill whenever creating a new domain entity, CRUD resource, database table, or permission set in the application.

## Execution Protocol
1. Call `mcp(laravel-boost/database-schema)` to check existing tables and foreign keys.
2. Run `php artisan electrik:make:model <ModelName>` or `php artisan electrik:make:resource <ModelName>` so the model is wired with `BelongsToTeam`.
3. Ensure the migration includes `$table->foreignId('team_id')->constrained()->cascadeOnDelete();` and an explicit `down()` method.
4. Create a Pest feature test verifying that Team A cannot access records belonging to Team B.
EOF

cat << 'EOF' > .agents/skills/slate-blade-ui/SKILL.md
---
name: slate-blade-ui
description: Build and refactor Blade views and Livewire 4 components using Electrik Slate 3 anonymous components (<x-slate::*>) and Tailwind CSS v4 tokens.
---

# Electrik Slate 3 & Livewire 4 UI Skill

## When to Use
Activate this skill when creating or editing dashboard pages, forms, modals, tables, navigation, or marketing blocks in `resources/views/` or `app/Livewire/`.

## Execution Protocol
1. Query the `electrik-slate` MCP server or read `https://slate.electrik.dev/llms.txt` to confirm exact prop names for `<x-slate::*>` components.
2. Use `<x-slate::*>` primitives for all UI elements and `<x-slate-block::*>` for marketing sections.
3. Use Slate semantic tokens (`--slate-primary`, `--slate-background`, etc.) and logical spacing (`ms-*`, `me-*`) for dark mode and RTL (`ar`) support.
EOF

cat << 'EOF' > .agents/skills/electrik-cashier-billing/SKILL.md
---
name: electrik-cashier-billing
description: Implement or modify team-level Stripe subscriptions, plan feature gates, add-ons, and metered usage billing in Electrik using Laravel Cashier.
---

# Electrik Team-Scoped Stripe Cashier Billing Skill

## When to Use
Activate this skill when implementing subscription checks, plan entitlements, Stripe webhooks, metered usage reporting, or pricing configuration.

## Execution Protocol
1. Always bill the active `Team` model (`auth()->user()->currentTeam`), never the `User` model.
2. Store all internal monetary values and usage ledgers as integer cents.
3. Update plan definitions in `config/electrik.php` and sync via `php artisan electrik:stripe:sync`.
EOF

cat << 'EOF' > .agents/skills/laravel-pest-verify/SKILL.md
---
name: laravel-pest-verify
description: Write and execute Pest 5 contract tests, multi-tenant isolation assertions, architecture tests, and code reviews for Laravel 13 and Electrik.
---

# Pest 5 Contract Verification & Code Review Skill

## When to Use
Activate this skill before and after implementing any feature, bugfix, or pull request review to enforce Red-Green-Refactor micro-transactions.

## Execution Protocol
1. Write a Pest test in `tests/Feature/` or `tests/Unit/` before writing production code, including cross-team tenant isolation assertions.
2. Run `vendor/bin/pest` and inspect failures via `mcp(laravel-boost/last-error)`.
3. Never declare a task complete until `vendor/bin/pest` exits with status `0`.
EOF

cat << 'EOF' > .agents/skills/laravel-pint-fix/SKILL.md
---
name: laravel-pint-fix
description: Format modified PHP 8.4 and Laravel 13 files using Laravel Pint in agent-optimized dirty mode before committing.
---

# Laravel Pint Dirty Self-Healing Skill

## When to Use
Activate this skill immediately after all Pest tests pass and before creating a Git commit snapshot.

## Execution Protocol
1. Run `vendor/bin/pint --dirty --format agent` to format only uncommitted modified files.
2. Re-run `vendor/bin/pest` if any structural refactor rules were applied.
EOF

cat << 'EOF' > .agents/skills/laravel-migration-validator/SKILL.md
---
name: laravel-migration-validator
description: Validate Laravel database migrations for team_id multi-tenant scoping, foreign key constraints, rollback safety, and zero destructive operations.
---

# Laravel Migration Validator Skill

## When to Use
Activate this skill whenever creating or modifying any file inside `database/migrations/`.

## Execution Protocol
1. Run `python3 .agents/skills/laravel-migration-validator/scripts/validate_migration.py database/migrations`.
2. Ensure the script reports `0 errors` before asking to run `php artisan migrate`.
EOF

cat << 'EOF' > .agents/skills/laravel-migration-validator/scripts/validate_migration.py
#!/usr/bin/env python3
import pathlib
import re
import sys

DESTRUCTIVE_PATTERNS = [
    (r"\bDB::statement\s*\(\s*['\"]DROP\b", "Raw DROP statement detected"),
    (r"\bDB::table\([^)]+\)->truncate\s*\(", "Destructive truncate() inside migration"),
]

CORE_DROP_RE = re.compile(
    r"\bSchema::dropIfExists\s*\(\s*['\"](users|teams|subscriptions)['\"]\s*\)",
    re.IGNORECASE,
)


def validate_file(path: pathlib.Path) -> list[str]:
    content = path.read_text(encoding="utf-8")
    errors: list[str] = []
    if "function up(" not in content:
        errors.append(f"{path.name}: Missing up() method.")
    if "function down(" not in content:
        errors.append(f"{path.name}: Missing explicit down() rollback method.")
    for pattern, msg in DESTRUCTIVE_PATTERNS:
        if re.search(pattern, content, re.IGNORECASE):
            errors.append(f"{path.name}: {msg}")
    down_match = re.search(r"\bfunction\s+down\s*\(", content)
    down_pos = down_match.start() if down_match else len(content)
    for match in CORE_DROP_RE.finditer(content):
        table_name = match.group(1).lower()
        creates_table = bool(
            re.search(
                rf"\bSchema::create\s*\(\s*['\"]{re.escape(table_name)}['\"]",
                content[:down_pos],
                re.IGNORECASE,
            )
        )
        if match.start() < down_pos or not creates_table:
            errors.append(f"{path.name}: Forbidden drop of core Electrik table '{table_name}'")
    return errors

def main() -> int:
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("database/migrations")
    files = sorted(target.glob("*.php")) if target.is_dir() else [target]
    all_errors: list[str] = []
    for f in files:
        all_errors.extend(validate_file(f))
    if all_errors:
        for err in all_errors:
            print(f"[MIGRATION_ERROR] {err}")
        return 1
    print(f"[OK] Validated {len(files)} migration file(s) successfully.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF
chmod +x .agents/skills/laravel-migration-validator/scripts/validate_migration.py

cat << 'EOF' > .agents/skills/adk-a2a-bridge/SKILL.md
---
name: adk-a2a-bridge
description: Build and connect in-app AI agents using the Laravel AI SDK (PHP) and Google ADK 2.0 multi-agent workflows (Python/Go/TS) via the Agent2Agent (A2A) protocol and MCP.
---

# Laravel AI SDK & Google ADK 2.0 Bridge Skill

## When to Use
Activate this skill when building customer-facing AI SaaS features inside `App\Ai\` or orchestrating multi-agent workflows in `adk_service/`.

## Execution Protocol
1. Use the Laravel AI SDK (`App\Ai\Agents\*` + `App\Ai\SkillRegistry`) for single-agent in-app tasks and Eloquent tool calls.
2. Use Google ADK 2.0 (`LlmAgent`, `SequentialAgent`, `ParallelAgent`, `LoopAgent`) in `adk_service/` for complex multi-agent orchestration, exposing an A2A endpoint (`/.well-known/agent.json`) consumed by Laravel queued jobs.
3. For inter-agent communication, use `App\Ai\A2a\RemoteAdkAgentTool` or call `POST /api/a2a/tasks/send` with strict tenant team isolation.
EOF

for skill_dir in .agents/skills/*; do
    skill_name="$(basename "$skill_dir")"
    ln -sfn "../../.agents/skills/$skill_name" ".ai/skills/$skill_name"
done

echo "[6/8] 写入 Laravel 端 A2A Server 控制器、Client Tool、路由与技能注册表..."
cat << 'EOF' > app/Ai/SkillRegistry.php
<?php

declare(strict_types=1);

namespace App\Ai;

use InvalidArgumentException;
use RuntimeException;

final class SkillRegistry
{
    /** @var array<string, string> */
    private array $paths = [];

    public function register(string $name, string $path): void
    {
        $this->paths[$name] = $path;
    }

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
EOF

cat << 'EOF' > app/Ai/A2a/A2aServerController.php
<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

final class A2aServerController // @pest-arch-ignore-line
{
    public function agentCard(): JsonResponse
    {
        return response()->json([
            '$schema' => 'https://a2a-protocol.org/schemas/v1/agent.json',
            'name' => config('app.name', 'ElectrikSaaS').'-agent',
            'description' => 'Multi-tenant Electrik Laravel SaaS Agent with Cashier billing and tenant scoping.',
            'version' => '1.0.0',
            'endpoint' => url('/api/a2a/tasks/send'),
            'capabilities' => [
                'streaming' => false,
                'stateful' => true,
                'pushNotifications' => false,
            ],
            'authentication' => [
                'type' => 'apiKey',
                'header' => 'X-A2A-Api-Key',
            ],
            'skills' => [
                [
                    'name' => 'tenant-query',
                    'description' => 'Execute team-scoped tenant queries and inspect tenant state.',
                    'tags' => ['electrik', 'saas', 'multi-tenant'],
                ],
                [
                    'name' => 'cashier-billing-status',
                    'description' => 'Verify team Stripe subscription and metered token balance.',
                    'tags' => ['billing', 'stripe', 'cashier'],
                ],
            ],
        ]);
    }

    public function handleTask(Request $request): JsonResponse
    {
        $expectedKey = (string) config('services.adk.server_api_key', '');
        if ($expectedKey !== '' && ! hash_equals($expectedKey, (string) $request->header('X-A2A-Api-Key', ''))) {
            return response()->json([
                'id' => (string) $request->input('id', ''),
                'status' => 'failed',
                'error' => [
                    'code' => 'INVALID_A2A_API_KEY',
                    'message' => 'Invalid or missing X-A2A-Api-Key header.',
                ],
            ], 401);
        }

        $validated = $request->validate([
            'id' => ['required', 'string'],
            'message.role' => ['required', 'string'],
            'message.parts' => ['required', 'array', 'min:1'],
            'message.parts.*.text' => ['required', 'string'],
            'metadata' => ['nullable', 'array'],
        ]);

        $teamId = (int) ($request->header('X-Electrik-Team-Id') ?? data_get($validated, 'metadata.team_id', 0));
        if ($teamId <= 0) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        $userPrompt = (string) data_get($validated, 'message.parts.0.text', '');
        Log::info('A2A Task received', ['id' => $validated['id'], 'team_id' => $teamId]);

        $agent = new \App\Ai\Agents\TenantCopilotAgent($teamId);
        $agentResponse = (string) $agent->prompt($userPrompt);

        return response()->json([
            'id' => $validated['id'],
            'status' => 'completed',
            'message' => [
                'role' => 'assistant',
                'parts' => [
                    ['text' => $agentResponse],
                ],
            ],
            'metadata' => [
                'team_id' => $teamId,
                'processed_at' => now()->toISOString(),
            ],
        ]);
    }
}
EOF

cat << 'EOF' > app/Ai/A2a/RemoteAdkAgentTool.php
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

    public function description(): Stringable|string
    {
        return 'Delegates deep reasoning, multi-agent orchestration, and complex workflows to an external Google ADK 2.0 agent over the A2A protocol.';
    }

    public function handle(Request $request): Stringable|string
    {
        $targetUrl = $this->endpoint ?? config('services.adk.endpoint', 'http://127.0.0.1:8080/a2a/tasks/send');
        $apiKey = $this->apiKey ?? config('services.adk.api_key', '');
        $taskId = (string) Str::uuid();

        $http = Http::timeout(60)
            ->withHeaders([
                'X-Electrik-Team-Id' => (string) $this->teamId,
                'Content-Type' => 'application/json',
            ]);

        if ($apiKey !== '') {
            $http = $http->withHeader('X-A2A-Api-Key', $apiKey);
        }

        $response = $http->post($targetUrl, [
            'id' => $taskId,
            'message' => [
                'role' => 'user',
                'parts' => [
                    ['text' => $request['task_prompt']],
                ],
            ],
            'metadata' => [
                'team_id' => $this->teamId,
                'skill_hint' => $request['skill_hint'] ?? null,
            ],
        ]);

        if (! $response->successful()) {
            throw new RuntimeException("A2A remote agent call failed [{$response->status()}]: {$response->body()}");
        }

        $data = $response->json();
        if (data_get($data, 'status') === 'failed') {
            $errMsg = data_get($data, 'error.message', 'Unknown A2A error');
            throw new RuntimeException("A2A agent execution failed: {$errMsg}");
        }

        return (string) data_get($data, 'message.parts.0.text', '');
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'task_prompt' => $schema->string()
                ->description('The explicit prompt and context to send to the remote ADK agent')
                ->required(),
            'skill_hint' => $schema->string()
                ->description('Optional targeted skill name to activate on the remote agent'),
        ];
    }
}
EOF

cat << 'EOF' > routes/a2a.php
<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

Route::get('/.well-known/agent.json', [\App\Ai\A2a\A2aServerController::class, 'agentCard'])
    ->name('a2a.agent-card');

Route::prefix('api/a2a')->middleware(['api'])->group(function () {
    Route::post('/tasks/send', [\App\Ai\A2a\A2aServerController::class, 'handleTask'])
        ->name('a2a.tasks.send');
});
EOF

echo "[7/8] 写入 Google ADK 2.0 A2A 服务端实现与 Python 依赖..."
cat << 'EOF' > adk_service/requirements.txt
google-adk>=2.0.0
fastapi>=0.115.0
uvicorn>=0.32.0
httpx>=0.27.0
pydantic>=2.9.0
EOF

cat << 'EOF' > adk_service/agent.py
"""Google ADK 2.0 Multi-Agent Workflow with native A2A Server & Client."""

from __future__ import annotations

import hmac
import os
from typing import Any

import uvicorn
from fastapi import FastAPI, Header, HTTPException, Request
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.tools import google_search

ADK_A2A_API_KEY = os.getenv("ADK_A2A_API_KEY", "")
LARAVEL_A2A_ENDPOINT = os.getenv(
    "LARAVEL_A2A_ENDPOINT", "http://127.0.0.1:8000/api/a2a/tasks/send"
)
MODEL_NAME = os.getenv("ADK_GEMINI_MODEL", "gemini-2.5-flash")

app = FastAPI(title="Electrik ADK 2.0 A2A Service", version="1.0.0")

triage_agent = LlmAgent(
    name="electrik_triage_agent",
    model=MODEL_NAME,
    description="Analyzes tenant requests, verifies team scoping, and structures execution plans.",
    instruction=(
        "You are a tenant-scoped SaaS triage specialist for an Electrik application. "
        "Classify the request priority, verify tenant boundaries, and output a structured plan."
    ),
    tools=[google_search],
    output_key="triage_plan",
)

execution_agent = LlmAgent(
    name="electrik_synthesis_agent",
    model=MODEL_NAME,
    description="Synthesizes the final grounded deliverable from the triage plan.",
    instruction=(
        "Read the {triage_plan} from session state and produce the final actionable response "
        "adhering strictly to Electrik and Slate 3 conventions."
    ),
    output_key="final_output",
)

root_agent = SequentialAgent(
    name="electrik_saas_orchestrator",
    description="End-to-end sequential multi-agent pipeline for Electrik SaaS tenants.",
    sub_agents=[triage_agent, execution_agent],
)


@app.get("/.well-known/agent.json")
def get_agent_card() -> dict[str, Any]:
    """Serve the Google ADK A2A discovery card."""
    return {
        "$schema": "https://a2a-protocol.org/schemas/v1/agent.json",
        "name": "adk-electrik-orchestrator",
        "description": "Google ADK 2.0 multi-agent orchestrator for Electrik SaaS workflows.",
        "version": "1.0.0",
        "endpoint": "/a2a/tasks/send",
        "capabilities": {
            "streaming": False,
            "stateful": True,
        },
        "authentication": {
            "type": "apiKey",
            "header": "X-A2A-Api-Key",
        },
        "skills": [
            {
                "name": "deep_tenant_reasoning",
                "description": "Executes sequential multi-step analysis and grounded synthesis.",
            }
        ],
    }


@app.post("/a2a/tasks/send")
async def send_a2a_task(
    request: Request,
    x_electrik_team_id: str | None = Header(default=None, alias="X-Electrik-Team-Id"),
    x_a2a_api_key: str | None = Header(default=None, alias="X-A2A-Api-Key"),
) -> dict[str, Any]:
    """Execute a tenant-scoped SequentialAgent workflow task over A2A."""
    if ADK_A2A_API_KEY and not hmac.compare_digest(
        ADK_A2A_API_KEY, x_a2a_api_key or ""
    ):
        raise HTTPException(
            status_code=401,
            detail={
                "status": "failed",
                "error": {
                    "code": "INVALID_A2A_API_KEY",
                    "message": "Invalid or missing X-A2A-Api-Key header.",
                },
            },
        )

    body = await request.json()
    task_id = body.get("id")
    message = body.get("message", {})
    parts = message.get("parts", [])
    if not parts or "text" not in parts[0]:
        raise HTTPException(status_code=400, detail="Missing message.parts.0.text")

    prompt = parts[0]["text"]
    raw_team_id = x_electrik_team_id or body.get("metadata", {}).get("team_id")
    try:
        team_id = int(raw_team_id) if raw_team_id is not None else 0
    except (TypeError, ValueError):
        team_id = 0

    if team_id <= 0:
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "MISSING_TENANT_CONTEXT",
                    "message": "Valid X-Electrik-Team-Id header or metadata.team_id is required.",
                },
            },
        )

    state: dict[str, Any] = {"tenant_team_id": str(team_id)}
    result = root_agent.run(prompt, state=state)
    output_text = state.get("final_output", str(result))

    return {
        "id": task_id,
        "status": "completed",
        "message": {
            "role": "assistant",
            "parts": [{"text": output_text}],
        },
        "metadata": {
            "team_id": team_id,
            "orchestrator": root_agent.name,
            "usage": {"total_tokens": max(1, len(prompt.split()) * 4)},
        },
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
EOF

echo "[8/8] 写入 Pest 5 架构测试与 A2A 契约测试套件..."
cat << 'EOF' > tests/Feature/ArchitectureTest.php
<?php

declare(strict_types=1);

arch()->preset()->php();
arch()->preset()->security();
arch()->preset()->laravel();

arch('strict types and no debug calls in app')
    ->expect('App')
    ->toUseStrictTypes()
    ->not->toUse(['dd', 'dump', 'die', 'var_dump', 'ray']);

arch('no forbidden abstraction layers that cause agent drift')
    ->expect([
        'App\Services',
        'App\Repositories',
        'App\Actions',
    ])
    ->not->toBeClasses()
    ->not->toBeInterfaces()
    ->not->toBeTraits()
    ->not->toBeEnums()
    ->not->toBeUsed();

arch('controllers follow naming and cohesion conventions')
    ->expect('App\Http\Controllers')
    ->toHaveSuffix('Controller');
EOF

cat << 'EOF' > tests/Feature/A2aProtocolTest.php
<?php

declare(strict_types=1);

use App\Ai\A2a\RemoteAdkAgentTool;
use Illuminate\Support\Facades\Http;
use Laravel\Ai\Tools\Request;

it('serves the A2A agent card at /.well-known/agent.json', function () {
    $response = $this->getJson('/.well-known/agent.json');

    $response->assertOk()
        ->assertJsonStructure([
            'name',
            'description',
            'version',
            'endpoint',
            'skills' => [
                '*' => ['name', 'description'],
            ],
        ]);
});

it('rejects A2A task without team context', function () {
    $response = $this->postJson('/api/a2a/tasks/send', [
        'id' => 'task-123',
        'message' => [
            'role' => 'user',
            'parts' => [['text' => 'Hello']],
        ],
    ]);

    $response->assertStatus(422)
        ->assertJsonPath('error.code', 'MISSING_TENANT_CONTEXT');
});

it('dispatches task to remote ADK agent via RemoteAdkAgentTool', function () {
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

    $tool = new RemoteAdkAgentTool(teamId: 42, endpoint: 'http://127.0.0.1:8080/a2a/tasks/send');
    $result = $tool->handle(new Request(['task_prompt' => 'Analyze tenant usage']));

    expect((string) $result)->toContain('Synthesized response from ADK');
});
EOF

echo "✅ Electrik × Antigravity 2.0 & CLI × A2A 协议工程化套件部署完成！"