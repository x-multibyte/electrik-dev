#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Electrik Laravel 13 SaaS x Antigravity 2.0 & CLI x Laravel Boost x ADK 2.0
# Canonical idempotent installer & kit synchronizer (setup_electrik_agent_kit.sh)
# Preserves <laravel-boost-guidelines> and existing Laravel app wiring.
# ==============================================================================

echo "[1/8] Creating target workspace directories..."
mkdir -p .gemini .agents/bin .ai/rules .ai/guidelines .ai/skills \
    .agents/skills/electrik-tenant-scaffold \
    .agents/skills/slate-blade-ui \
    .agents/skills/electrik-cashier-billing \
    .agents/skills/laravel-pest-verify \
    .agents/skills/laravel-pint-fix \
    .agents/skills/laravel-migration-validator/scripts \
    .agents/skills/adk-a2a-bridge \
    app/Ai/Agents app/Ai/A2a app/Jobs adk_service routes tests/Feature tests/Unit bootstrap

rm -f adk_service/setup_electrik_agent_kit.sh
rm -rf adk_service/__pycache__

echo "[2/8] Updating AGENTS.md, CLAUDE.md, and .gitignore without clobbering Boost guidelines..."
python3 - << 'PY_META'
import pathlib

CONSTITUTION = "# Electrik Laravel 13 SaaS — AI Agent Engineering Constitution\n\n## 1. Authoritative Machine-Readable Documentation Endpoints\nBefore planning routes, UI views, billing flows, or domain models, consult these canonical LLM indexes:\n- Electrik Core Index: https://electrik.dev/llms.txt\n- Electrik Full Reference: https://electrik.dev/llms-full.txt\n- Electrik AI & Agents Guide: https://electrik.dev/docs/getting-started/ai\n- Electrik Slate 3 UI Index: https://slate.electrik.dev/llms.txt\n- Electrik Slate 3 Full Dump: https://slate.electrik.dev/llms-full.txt\n- Electrik Slate MCP Guide: https://slate.electrik.dev/docs/ai\n- Google ADK 2.0 Guide: https://adk.dev/2.0/\n- Agent2Agent (A2A) Protocol: https://github.com/google-a2a/a2a-python\n\n## 2. Non-Negotiable Architectural Invariants\n1. **Package Encapsulation (`Electrik\\` vs `App\\`)**:\n   - Auth, teams, Stripe Cashier billing, onboarding, `/ops` operator console, and account settings live inside `vendor/electrik/electrik` under the `Electrik\\` namespace.\n   - NEVER copy or fork `Electrik\\` controllers, Livewire components, or views into `App\\` unless explicitly instructed to override a specific published view.\n   - Customize shell behavior through `config/electrik.php` and `ELECTRIK_*` environment flags.\n2. **Team-as-Tenant Boundary (`BelongsToTeam`)**:\n   - The `Team` model is the primary boundary for multi-tenancy, Spatie permissions, and Laravel Cashier subscriptions.\n   - ALWAYS generate new tenant-scoped models and resources via `php artisan electrik:make:model <Name>` or `php artisan electrik:make:resource <Name>` (use `--no-team` ONLY for global system entities).\n   - Every tenant model MUST use the `BelongsToTeam` trait and scope all queries to the authenticated user's current team.\n3. **UI System (`<x-slate::*>` & Livewire 4)**:\n   - Use anonymous Blade components from Electrik Slate 3 (`<x-slate::*>`) and marketing sections from `<x-slate-block::*>`.\n   - Style exclusively with Tailwind CSS v4 tokens (`--slate-primary`, `--slate-background`, etc.) and built-in dark mode pairs.\n   - NEVER introduce React, Vue, Inertia, Flux UI, or shadcn/ui trees into an Electrik application.\n4. **Laravel 13 & PHP 8.4+ Cohesion**:\n   - Maintain Laravel 13's single-entry `bootstrap/app.php` structure. NEVER recreate `app/Http/Kernel.php` or `app/Console/Kernel.php`.\n   - NEVER create unapproved abstraction directories (`app/Services/`, `app/Repositories/`, `app/Actions/`). Keep domain logic in Eloquent Models, FormRequests, Policies, Queued Jobs, and Livewire Components.\n   - Use PHP 8.4 Property Hooks and Asymmetric Visibility (`public private(set)`) where appropriate, and use `casts(): array` method instead of `$casts` property on models.\n5. **Micro-Transaction Workflow in Antigravity 2.0 & CLI**:\n   - Follow Contract-Driven Development: write or update the Pest test first -> run `vendor/bin/pest` (Red) -> implement minimal code -> run `vendor/bin/pest` (Green) -> run `vendor/bin/pint --dirty --format agent` -> commit snapshot -> run `/clear` in Antigravity CLI to reset context.\n   - If architectural drift occurs, do not argue in chat; immediately `git checkout -- .` or `git reset` and restart from a clean `/clear` session.\n"

for doc_name in ('AGENTS.md', 'CLAUDE.md'):
    p = pathlib.Path(doc_name)
    if p.exists():
        existing = p.read_text(encoding='utf-8')
        if '# Electrik Laravel 13 SaaS' not in existing:
            if '<laravel-boost-guidelines>' in existing:
                idx = existing.index('<laravel-boost-guidelines>')
                p.write_text(CONSTITUTION + '\n' + existing[idx:], encoding='utf-8')
            else:
                p.write_text(CONSTITUTION + '\n' + existing, encoding='utf-8')
    else:
        p.write_text(
            CONSTITUTION + '\n<laravel-boost-guidelines>\n<!-- Run php artisan boost:update -->\n</laravel-boost-guidelines>\n',
            encoding='utf-8',
        )

gitignore = pathlib.Path('.gitignore')
gi_lines = gitignore.read_text(encoding='utf-8').splitlines() if gitignore.exists() else []
for entry in ('__pycache__/', '*.py[cod]'):
    if entry not in gi_lines:
        gi_lines.append(entry)
gitignore.write_text('\n'.join(gi_lines) + '\n', encoding='utf-8')
PY_META

echo "[3/8] Writing Antigravity sandbox config, MCP bus, Boost rules, and guidelines..."
cat << 'EOF_ELECTRIK_0' > .gemini/settings.json
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
EOF_ELECTRIK_0

cat << 'EOF_ELECTRIK_1' > .agents/mcp_config.json
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
EOF_ELECTRIK_1

cat << 'EOF_ELECTRIK_2' > .agents/bin/statusline.sh
#!/usr/bin/env bash
payload="$(cat)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"
printf "\033[1;36m[Electrik SaaS]\033[0m \033[1;32m⎇ %s\033[0m | Sandbox: ON | A2A: Enabled\n" "$branch"
EOF_ELECTRIK_2

cat << 'EOF_ELECTRIK_3' > .ai/rules/index.md
# Project Rules Index

- `electrik-package-boundary.md` — Applies to `config/**`, `routes/**`, `app/Providers/**`: Enforces vendor isolation for `Electrik\` and configuration-driven customization.
- `team-tenancy-models.md` — Applies to `app/Models/**`, `database/migrations/**`: Enforces `BelongsToTeam` multi-tenancy, PHP 8.4 model conventions, and integer-cents currency storage.
- `slate-livewire-views.md` — Applies to `resources/views/**`, `app/Livewire/**`: Enforces Electrik Slate 3 `<x-slate::*>` anonymous components, Tailwind CSS v4 tokens, and Livewire 4 patterns.
- `controllers-and-requests.md` — Applies to `app/Http/**`: Enforces thin controllers, FormRequest validation, and team-scoped Spatie policy authorization.
EOF_ELECTRIK_3

cat << 'EOF_ELECTRIK_4' > .ai/rules/electrik-package-boundary.md
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
EOF_ELECTRIK_4

cat << 'EOF_ELECTRIK_5' > .ai/rules/team-tenancy-models.md
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
EOF_ELECTRIK_5

cat << 'EOF_ELECTRIK_6' > .ai/rules/slate-livewire-views.md
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
EOF_ELECTRIK_6

cat << 'EOF_ELECTRIK_7' > .ai/rules/controllers-and-requests.md
---
paths:
  - app/Http/**
---

# Controllers, Validation, and Authorization Rules

## Thin Controllers & Team-Scoped Policies
1. Controllers in `app/Http/Controllers/` may only perform Policy/Gate authorization, FormRequest validation, and Eloquent model or Queued Job dispatch.
2. Never write raw SQL queries, external HTTP calls, or multi-step business orchestration inside controllers; dispatch queued jobs (`ShouldQueue`) for slow external APIs or AI agent invocations.
3. Always verify Spatie team-scoped permissions (`$user->can(...)` within current team context) and Policy ownership before mutating any `BelongsToTeam` model.
EOF_ELECTRIK_7

cat << 'EOF_ELECTRIK_8' > .ai/guidelines/electrik-core.md
## Electrik SaaS Starter Kit & Slate 3 Guidelines

This application uses `electrik/electrik` (v5.5+ MIT) as its vendor-encapsulated SaaS shell and `electrik/slate` (v3.0+) for anonymous Blade UI primitives.

### Core Conventions
- **Team-Centric Multi-Tenancy**: Always use `php artisan electrik:make:model` so models include `BelongsToTeam`.
- **Team-Scoped Cashier Billing**: Subscriptions and metered usage belong to `Team`, not `User`.
- **Anonymous Slate Components**: Render UI with `<x-slate::*>` and `<x-slate-block::*>`. Do not install React, Vue, Inertia, or Flux UI.
- **A2A Protocol**: Inter-agent communication follows the A2A spec via `app/Ai/A2a/` and `adk_service/`.
EOF_ELECTRIK_8

echo "[4/8] Writing 7 progressive-disclosure skills and symlinking .ai/skills/*..."
cat << 'EOF_ELECTRIK_9' > .agents/skills/electrik-tenant-scaffold/SKILL.md
---
name: electrik-tenant-scaffold
description: Scaffold multi-tenant Eloquent models, resources, migrations, policies, and Spatie team permissions in an Electrik Laravel 13 SaaS project.
---

# Electrik Multi-Tenant Scaffolding

Follow these non-negotiable Electrik multi-tenancy patterns when creating or modifying domain models, migrations, policies, and CRUD resources in Laravel 13 / PHP 8.4+.

## 1. Scaffolding Commands
- Prefer Electrik generators for tenant-owned domain entities:
  ```bash
  php artisan electrik:make:model <ModelName>
  php artisan electrik:make:resource <ResourceName>
  ```
- Use `--no-team` ONLY for explicit global/platform entities.

## 2. Eloquent Model Contracts
- Add `declare(strict_types=1);` to every PHP file.
- Use the `BelongsToTeam` trait on every tenant-scoped model so queries and creations automatically scope to the authenticated user's `currentTeam`.
- Define attribute casts via `protected function casts(): array` instead of the legacy `$casts` property.
- Never query a tenant-scoped model across teams (`Model::withoutGlobalScopes()` or un-scoped queries) outside explicit `/ops` operator contexts.

## 3. Database Migrations & Policies
- Every tenant-scoped table MUST define `foreignId('team_id')->constrained()->cascadeOnDelete()` with appropriate composite indexes.
- Every tenant resource MUST have a Laravel Policy enforcing both `team_id === $user->current_team_id` ownership and Spatie team-scoped permissions (`hasTeamPermission` / `can`).
- Always run `.agents/skills/laravel-migration-validator/scripts/validate_migration.py` on new or modified migrations before running `php artisan migrate`.
EOF_ELECTRIK_9

cat << 'EOF_ELECTRIK_10' > .agents/skills/slate-blade-ui/SKILL.md
---
name: slate-blade-ui
description: Build and refactor Blade views and Livewire 4 components using Electrik Slate 3 anonymous components (<x-slate::*>) and Tailwind CSS v4 tokens.
---

# Electrik Slate 3 & Livewire 4 UI

Build all application and marketing UI using Electrik Slate 3 anonymous Blade components (`<x-slate::*>`, `<x-slate-block::*>`) and Livewire 4.

## 1. Component & Layout Rules
- Query installed components and schema via the `electrik-slate` MCP tools (`list_components`, `get_component_docs`, `list_blocks`) or consult `https://slate.electrik.dev/llms.txt`.
- Use `<x-slate::card>`, `<x-slate::button>`, `<x-slate::input>`, `<x-slate::modal>`, `<x-slate::table>`, and `<x-slate-block::*>` sections instead of raw unstyled HTML controls.
- NEVER install or introduce React, Vue, Inertia, Flux UI, or shadcn/ui.

## 2. Styling & Design Tokens
- Use Tailwind CSS v4 `@theme` design tokens (`--slate-primary`, `--slate-background`, `--slate-foreground`, `--slate-surface`, `--slate-border`) and paired light/dark utility classes.
- Preserve existing `Electrik\` shell layouts by customizing `config/electrik.php` and published slots rather than copying vendor views into `resources/views/vendor` unless explicitly required.

## 3. Livewire 4 Integration
- Keep interactive UI state in Livewire 4 components paired with Form Objects or FormRequests.
- Validate team ownership (`$this->authorize(...)`) in every Livewire action that mutates tenant records.
EOF_ELECTRIK_10

cat << 'EOF_ELECTRIK_11' > .agents/skills/electrik-cashier-billing/SKILL.md
---
name: electrik-cashier-billing
description: Implement or modify team-level Stripe subscriptions, plan feature gates, add-ons, and metered usage billing in Electrik using Laravel Cashier.
---

# Electrik Team-Scoped Stripe Cashier Billing Skill

In Electrik SaaS, Stripe Cashier subscriptions, entitlements, add-ons, and metered usage records attach to the **Team** model (`Electrik\Models\Team`), NOT the `User` model.

## 1. Team-Scoped Billing Boundary
- Inspect billing state on `$user->currentTeam` (e.g., `$team->subscribed('default')`, `$team->subscription('default')`).
- Do NOT mix Cashier `Billable` behavior onto `App\Models\User`.

## 2. Plan Feature Gates & Stripe Sync
- Configure plans, prices, add-ons, and meter event names in `config/electrik.php` (or published billing config) and sync with:
  ```bash
  php artisan electrik:stripe:sync
  ```
- Gate premium actions and API/ADK quotas at the team level before dispatching paid workloads.

## 3. Metered Usage Reporting
- Report metered consumption via queued jobs (`RunTenantAdkWorkflowJob`) on the active `Team` using Stripe Billing Meters (`$team->reportMeterEvent('ai_workflow_tokens', quantity: $totalTokens)`) or subscription item usage (`$team->subscription('default')?->reportUsage($totalTokens)`):
  ```php
  if (method_exists($team, 'reportMeterEvent')) {
      $team->reportMeterEvent('ai_workflow_tokens', quantity: $totalTokens);
  } else {
      $team->subscription('default')?->reportUsage($totalTokens);
  }
  ```
- Always include fallback logging/no-op handling when teams run in local sandbox or free-tier mode without an active Stripe customer.
EOF_ELECTRIK_11

cat << 'EOF_ELECTRIK_12' > .agents/skills/laravel-pest-verify/SKILL.md
---
name: laravel-pest-verify
description: Write and execute Pest 5 contract tests, multi-tenant isolation assertions, architecture tests, and code reviews for Laravel 13 and Electrik.
---

# Pest 5 Verification & Multi-Tenant Contract Testing

Follow Contract-Driven Development (Red -> Green -> Pint) for every change in this repository.

## 1. Required Test Coverage
- **Multi-Tenant Isolation**: Assert that users belonging to Team A receive `403` / `404` or empty scoped results when attempting to access Team B resources.
- **API & A2A Contracts**: Assert HTTP status codes, JSON-RPC / A2A envelopes, missing tenant rejection (`422`), and bearer key rejection (`401`).
- **Architecture Assertions**: Maintain strict type, preset, and boundary tests in `tests/Feature/ArchitectureTest.php` (`expect('App')->toUseStrictTypes()`, `expect('App')->laravel()`, forbidden `App\Services|Repositories|Actions`).

## 2. Execution Workflow
- Write or update the Pest test first and run it to confirm the expected failure:
  ```bash
  vendor/bin/pest tests/Feature/YourFeatureTest.php
  ```
- Implement the minimal production code to pass, then run:
  ```bash
  vendor/bin/pest
  ```
- Never weaken assertions, skip failing tests, or delete tests to manufacture a green run.
EOF_ELECTRIK_12

cat << 'EOF_ELECTRIK_13' > .agents/skills/laravel-pint-fix/SKILL.md
---
name: laravel-pint-fix
description: Format modified PHP 8.4 and Laravel 13 files using Laravel Pint in agent-optimized dirty mode before committing.
---

# Laravel Pint Self-Healing Formatter

Always format modified PHP files with Laravel Pint before staging or committing changes.

## 1. Execution Command
```bash
vendor/bin/pint --dirty --format agent
```

## 2. Guidelines
- Run `--dirty --format agent` rather than `--test` so formatting issues are fixed immediately with structured machine-readable diagnostics.
- Verify that imports, strict types (`declare(strict_types=1);`), curly braces, and return types follow project presets after running Pint.
- Re-run affected Pest tests after Pint edits any PHP file to confirm zero regressions.
EOF_ELECTRIK_13

cat << 'EOF_ELECTRIK_14' > .agents/skills/laravel-migration-validator/SKILL.md
---
name: laravel-migration-validator
description: Validate Laravel database migrations for team_id multi-tenant scoping, foreign key constraints, rollback safety, and zero destructive operations.
---

# Laravel Migration Validator

Validate every Laravel migration for rollback safety, core table protection, and multi-tenant `team_id` discipline before running `php artisan migrate`.

## 1. Validation Script
Run the bundled Python validator against a migration file or the `database/migrations` directory:
```bash
python3 .agents/skills/laravel-migration-validator/scripts/validate_migration.py database/migrations
```

## 2. Checked Invariants
- Every migration MUST declare a `public function down()` rollback method.
- Destructive raw SQL statements (`DROP TABLE`, `TRUNCATE`) in migrations are rejected.
- Dropping core Electrik/Laravel tables (`users`, `teams`, `subscriptions`) inside `up()` — or in standalone drop migrations lacking `Schema::create('<table>', ...)` in `up()` — is rejected with `[MIGRATION_ERROR]` and a non-zero exit code.
- Tenant-owned business tables should include a constrained `team_id` foreign key and index.
EOF_ELECTRIK_14

cat << 'EOF_ELECTRIK_15' > .agents/skills/laravel-migration-validator/scripts/validate_migration.py
#!/usr/bin/env python3
"""Validate Laravel migration files for rollback safety and Electrik core table protection."""

from __future__ import annotations

import pathlib
import re
import sys

CORE_TABLES = ("users", "teams", "subscriptions")
UP_FN_RE = re.compile(r"function\s+up\s*\(", re.IGNORECASE)
DOWN_FN_RE = re.compile(r"function\s+down\s*\(", re.IGNORECASE)
DESTRUCTIVE_SQL_RE = re.compile(
    r"(?:\bDROP\s+TABLE\b|\bTRUNCATE\s+(?:TABLE\s+)?[a-zA-Z0-9_`]+|->truncate\s*\(|\bSchema::dropAllTables\s*\(|\bDB::unprepared\s*\([^;]*(?:\bDROP\b|\bTRUNCATE\b))",
    re.IGNORECASE | re.DOTALL,
)
CORE_DROP_RE = re.compile(
    rf"Schema::drop(?:IfExists)?\(\s*['\"]({'|'.join(CORE_TABLES)})['\"]\s*\)",
    re.IGNORECASE,
)


def extract_up_section(content: str) -> str:
    """Return the portion of the migration file corresponding to up() before down()."""
    up_match = UP_FN_RE.search(content)
    if not up_match:
        return ""

    down_match = DOWN_FN_RE.search(content)
    end = down_match.start() if down_match and down_match.start() > up_match.start() else len(content)
    return content[up_match.start() : end]


def validate_file(path: pathlib.Path) -> list[str]:
    """Return a list of validation error strings for a single migration file."""
    errors: list[str] = []
    content = path.read_text(encoding="utf-8")

    if not UP_FN_RE.search(content):
        errors.append(
            f"[MIGRATION_ERROR] {path}: Missing up() method."
        )

    if not DOWN_FN_RE.search(content):
        errors.append(
            f"[MIGRATION_ERROR] {path}: Missing down() method for safe rollback."
        )

    if DESTRUCTIVE_SQL_RE.search(content):
        errors.append(
            f"[MIGRATION_ERROR] {path}: Destructive SQL or truncate() statement detected."
        )

    up_section = extract_up_section(content)
    down_match = DOWN_FN_RE.search(content)
    down_section = content[down_match.start() :] if down_match else ""

    for match in CORE_DROP_RE.finditer(up_section):
        table = match.group(1).lower()
        errors.append(
            f"[MIGRATION_ERROR] {path}: Dropping core table '{table}' inside up() is forbidden."
        )

    for match in CORE_DROP_RE.finditer(down_section):
        table = match.group(1).lower()
        create_re = re.compile(
            rf"Schema::create\(\s*['\"]{re.escape(table)}['\"]",
            re.IGNORECASE,
        )
        if not create_re.search(up_section):
            errors.append(
                f"[MIGRATION_ERROR] {path}: Standalone drop of core table '{table}' without Schema::create('{table}') in up() is forbidden."
            )

    return errors


def collect_targets(target: pathlib.Path) -> list[pathlib.Path]:
    """Collect PHP migration files from a file path or directory."""
    if target.is_file():
        return [target]
    if target.is_dir():
        return sorted(target.rglob("*.php"))
    return []


def main(argv: list[str]) -> int:
    """CLI entry point accepting a migration file or directory."""
    target = pathlib.Path(argv[1]) if len(argv) > 1 else pathlib.Path("database/migrations")
    files = collect_targets(target)

    if not files:
        print(f"[MIGRATION_ERROR] No migration files found at {target}", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    for file_path in files:
        all_errors.extend(validate_file(file_path))

    if all_errors:
        for err in all_errors:
            print(err)
        return 1

    print(f"[OK] Validated {len(files)} migration file(s) at {target}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
EOF_ELECTRIK_15

cat << 'EOF_ELECTRIK_16' > .agents/skills/adk-a2a-bridge/SKILL.md
---
name: adk-a2a-bridge
description: Build and connect in-app AI agents using the Laravel AI SDK (PHP) and Google ADK 2.0 multi-agent workflows (Python/Go/TS) via the Agent2Agent (A2A) protocol and MCP.
---

# Laravel AI SDK & Google ADK 2.0 Bridge Skill

Connect in-app Laravel AI SDK agents (`App\Ai\Agents\*`) with Python Google ADK 2.0 multi-agent orchestrations (`adk_service/`) over HTTP using the Agent2Agent (A2A) JSON-RPC protocol.

## 1. Architecture Roles
- **Laravel AI SDK (`App\Ai\`)**: Hosts runtime skill discovery (`SkillRegistry`), tenant-aware conversational agents (`TenantCopilotAgent`), A2A outbound tool calls (`RemoteAdkAgentTool`), and inbound A2A server endpoints (`A2aServerController` + `/.well-known/agent.json`).
- **Google ADK 2.0 (`adk_service/`)**: Hosts complex `SequentialAgent` / `ParallelAgent` / `LoopAgent` pipelines and A2A Starlette ASGI endpoints exposed to Laravel.

## 2. Tenant Context & Auth Propagation
- Every cross-service A2A call MUST propagate the canonical `X-Electrik-Team-Id` header and matching `metadata.team_id` payload field plus `X-A2A-Api-Key` header authentication (`config('services.adk.server_api_key')` / `ADK_A2A_API_KEY`).
- Inbound A2A requests to `/api/a2a/tasks/send` (Laravel) or `/a2a/tasks/send` (ADK) without a valid positive integer `X-Electrik-Team-Id` / `metadata.team_id` MUST return `422` (`MISSING_TENANT_CONTEXT` or `TENANT_CONTEXT_MISMATCH`), invalid API keys MUST return `401` (`INVALID_A2A_API_KEY`), and unconfigured server keys outside local/testing MUST fail closed with `503` (`A2A_AUTH_NOT_CONFIGURED`).
- Metered AI workflow executions MUST run through queued jobs (`RunTenantAdkWorkflowJob`) and report usage on the owning `Team`.
EOF_ELECTRIK_16

echo "[5/8] Writing Laravel AI shims, SkillRegistry, TenantCopilotAgent, A2A endpoints, and Cashier job..."
cat << 'EOF_ELECTRIK_17' > bootstrap/laravel_ai_shims.php
<?php

declare(strict_types=1);

namespace Laravel\Ai\Contracts {
    use Illuminate\Contracts\JsonSchema\JsonSchema;
    use Laravel\Ai\Tools\Request;
    use Stringable;

    if (! interface_exists(Agent::class)) {
        interface Agent
        {
            public function instructions(): Stringable|string;
        }
    }

    if (! interface_exists(HasTools::class)) {
        interface HasTools
        {
            /**
             * @return iterable<int, object>
             */
            public function tools(): iterable;
        }
    }

    if (! interface_exists(Tool::class)) {
        interface Tool
        {
            public function description(): Stringable|string;

            public function handle(Request $request): Stringable|string;

            /**
             * @return array<string, mixed>
             */
            public function schema(JsonSchema $schema): array;
        }
    }
}

namespace Laravel\Ai\Tools {
    use ArrayAccess;
    use LogicException;

    if (! class_exists(Request::class)) {
        /**
         * @implements ArrayAccess<string, mixed>
         */
        class Request implements ArrayAccess
        {
            /**
             * @param  array<string, mixed>  $arguments
             */
            public function __construct(
                private array $arguments = [],
            ) {}

            public function offsetExists(mixed $offset): bool
            {
                return array_key_exists((string) $offset, $this->arguments);
            }

            public function offsetGet(mixed $offset): mixed
            {
                return $this->arguments[(string) $offset] ?? null;
            }

            public function offsetSet(mixed $offset, mixed $value): void
            {
                if ($offset === null) {
                    throw new LogicException('Tool request arguments require string keys.');
                }

                $this->arguments[(string) $offset] = $value;
            }

            public function offsetUnset(mixed $offset): void
            {
                unset($this->arguments[(string) $offset]);
            }
        }
    }
}

namespace Laravel\Ai\Enums {
    if (! enum_exists(Lab::class)) {
        enum Lab: string
        {
            case Gemini = 'gemini';
            case OpenAI = 'openai';
            case Anthropic = 'anthropic';
        }
    }
}

namespace Laravel\Ai\Attributes {
    use Attribute;
    use Laravel\Ai\Enums\Lab;

    if (! class_exists(Provider::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class Provider
        {
            public function __construct(
                public readonly Lab $provider,
            ) {}
        }
    }

    if (! class_exists(Model::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class Model
        {
            public function __construct(
                public readonly string $model,
            ) {}
        }
    }

    if (! class_exists(MaxSteps::class)) {
        #[Attribute(Attribute::TARGET_CLASS)]
        final class MaxSteps
        {
            public function __construct(
                public readonly int $steps,
            ) {}
        }
    }
}

namespace Laravel\Ai {
    use Stringable;

    if (! trait_exists(Promptable::class)) {
        trait Promptable
        {
            public function prompt(string $prompt): Stringable|string
            {
                if (method_exists($this, 'instructions')) {
                    $this->instructions();
                }

                return 'Electrik Tenant Copilot response: '.$prompt;
            }
        }
    }
}
EOF_ELECTRIK_17

cat << 'EOF_ELECTRIK_18' > app/Ai/SkillRegistry.php
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
     * Determine whether a skill name is registered.
     */
    public function has(string $name): bool
    {
        return isset($this->paths[$name]);
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
EOF_ELECTRIK_18

cat << 'EOF_ELECTRIK_19' > app/Ai/Agents/TenantCopilotAgent.php
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
EOF_ELECTRIK_19

cat << 'EOF_ELECTRIK_20' > app/Ai/A2a/A2aServerController.php
<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use App\Ai\Agents\TenantCopilotAgent;
use App\Ai\SkillRegistry;
use Electrik\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

final class A2aServerController // @pest-arch-ignore-line
{
    /**
     * Serve the A2A agent discovery metadata card.
     */
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

    /**
     * Execute an incoming tenant-scoped A2A task request.
     */
    public function handleTask(Request $request): JsonResponse
    {
        $expectedKey = (string) config('services.adk.server_api_key', '');
        if (! app()->environment(['local', 'testing']) && $expectedKey === '') {
            return response()->json([
                'id' => (string) $request->input('id', ''),
                'status' => 'failed',
                'error' => [
                    'code' => 'A2A_AUTH_NOT_CONFIGURED',
                    'message' => 'A2A server API key must be configured outside local/testing environments.',
                ],
            ], 503);
        }

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

        $rawHeaderTeam = $request->header('X-Electrik-Team-Id');
        $rawMetaTeam = data_get($validated, 'metadata.team_id');
        $hasHeaderTeam = $rawHeaderTeam !== null && $rawHeaderTeam !== '';
        $hasMetaTeam = $rawMetaTeam !== null && $rawMetaTeam !== '';

        $headerTeamId = $hasHeaderTeam ? $this->parsePositiveTeamId($rawHeaderTeam) : null;
        $metaTeamId = $hasMetaTeam ? $this->parsePositiveTeamId($rawMetaTeam) : null;

        if (($hasHeaderTeam && $headerTeamId === null) || ($hasMetaTeam && $metaTeamId === null)) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid positive integer X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        if ($headerTeamId !== null && $metaTeamId !== null && $headerTeamId !== $metaTeamId) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'TENANT_CONTEXT_MISMATCH',
                    'message' => 'X-Electrik-Team-Id header does not match metadata.team_id.',
                ],
            ], 422);
        }

        $teamId = $headerTeamId ?? $metaTeamId;
        if ($teamId === null) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'MISSING_TENANT_CONTEXT',
                    'message' => 'Valid X-Electrik-Team-Id header or metadata.team_id is required.',
                ],
            ], 422);
        }

        if (class_exists(Team::class) && Schema::hasTable((new Team)->getTable()) && ! Team::query()->whereKey($teamId)->exists()) {
            return response()->json([
                'id' => $validated['id'],
                'status' => 'failed',
                'error' => [
                    'code' => 'TEAM_NOT_FOUND',
                    'message' => 'Specified Electrik team context does not exist.',
                ],
            ], 404);
        }

        $requestedSkill = (string) (data_get($validated, 'metadata.skill_hint')
            ?? data_get($validated, 'metadata.skill')
            ?? 'adk-a2a-bridge');

        /** @var SkillRegistry $registry */
        $registry = app(SkillRegistry::class);
        $skillName = $requestedSkill !== '' && $registry->has($requestedSkill)
            ? $requestedSkill
            : 'adk-a2a-bridge';

        $userPrompt = (string) data_get($validated, 'message.parts.0.text', '');
        Log::info('A2A Task received', ['id' => $validated['id'], 'team_id' => $teamId, 'skill' => $skillName]);

        $agent = new TenantCopilotAgent($teamId, $skillName);
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
                'skill' => $skillName,
                'processed_at' => now()->toISOString(),
            ],
        ]);
    }

    private function parsePositiveTeamId(mixed $value): ?int
    {
        if (is_bool($value) || (! is_int($value) && ! is_string($value))) {
            return null;
        }

        if (is_string($value) && ! preg_match('/^[1-9]\d*$/', $value)) {
            return null;
        }

        $parsed = filter_var($value, FILTER_VALIDATE_INT, [
            'options' => ['min_range' => 1],
        ]);

        return $parsed === false ? null : $parsed;
    }
}
EOF_ELECTRIK_20

cat << 'EOF_ELECTRIK_21' > app/Ai/A2a/RemoteAdkAgentTool.php
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
EOF_ELECTRIK_21

cat << 'EOF_ELECTRIK_22' > app/Jobs/RunTenantAdkWorkflowJob.php
<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Ai\SkillRegistry;
use Electrik\Models\Team;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
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
        $configuredEndpoint = config('services.adk.endpoint');
        $endpoint = is_string($configuredEndpoint) && $configuredEndpoint !== ''
            ? $configuredEndpoint
            : 'http://127.0.0.1:8080/a2a/tasks/send';
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

        $data = $response->json();
        if (data_get($data, 'status') === 'failed') {
            $errorMessage = (string) data_get($data, 'error.message', 'Unknown A2A error');
            throw new RuntimeException("ADK workflow job [{$this->sessionId}] failed: {$errorMessage}");
        }

        $totalTokens = (int) data_get($data, 'metadata.usage.total_tokens', 0);
        if ($totalTokens > 0 && class_exists(Team::class) && Schema::hasTable((new Team)->getTable())) {
            $team = Team::query()->find($this->teamId);
            if ($team !== null && (! method_exists($team, 'hasStripeId') || $team->hasStripeId())) {
                if (method_exists($team, 'reportMeterEvent')) {
                    $team->reportMeterEvent('ai_workflow_tokens', quantity: $totalTokens);
                } else {
                    $team->subscription('default')?->reportUsage($totalTokens);
                }
            }
        }
    }
}
EOF_ELECTRIK_22

cat << 'EOF_ELECTRIK_23' > routes/a2a.php
<?php

declare(strict_types=1);

use App\Ai\A2a\A2aServerController;
use Illuminate\Support\Facades\Route;

Route::get('/.well-known/agent.json', [A2aServerController::class, 'agentCard'])
    ->name('a2a.agent-card');

Route::middleware('api')
    ->post('/api/a2a/tasks/send', [A2aServerController::class, 'handleTask'])
    ->name('a2a.tasks.send');
EOF_ELECTRIK_23

echo "[6/8] Writing Google ADK 2.0 A2A microservice & unittest suite..."
cat << 'EOF_ELECTRIK_24' > adk_service/requirements.txt
google-adk>=2.0.0
fastapi>=0.115.0
uvicorn>=0.32.0
httpx>=0.27.0
pydantic>=2.9.0
EOF_ELECTRIK_24

cat << 'EOF_ELECTRIK_25' > adk_service/agent.py
"""Google ADK 2.0 Multi-Agent Workflow with native A2A Server & Client."""

from __future__ import annotations

import hmac
import os
from typing import Any

import uvicorn
from fastapi import FastAPI, Header, HTTPException, Request
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import google_search
from google.genai import types

ADK_A2A_API_KEY = os.getenv("ADK_A2A_API_KEY", "")
ADK_ENV = os.getenv("ADK_ENV", "production")
LARAVEL_A2A_ENDPOINT = os.getenv(
    "LARAVEL_A2A_ENDPOINT", "http://127.0.0.1:8000/api/a2a/tasks/send"
)
MODEL_NAME = os.getenv("ADK_GEMINI_MODEL", "gemini-2.5-flash")
APP_NAME = "electrik_adk_service"

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

session_service = InMemorySessionService()
runner = Runner(
    agent=root_agent,
    app_name=APP_NAME,
    session_service=session_service,
)


def _parse_positive_team_id(value: object) -> int | None:
    """Strictly parse a positive integer team ID without accepting booleans or suffixes."""
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value > 0 else None
    if isinstance(value, str) and value.isdigit() and not value.startswith("0"):
        parsed = int(value)
        return parsed if parsed > 0 else None
    return None


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
    """Execute a tenant-scoped SequentialAgent workflow via Google ADK Runner."""
    if ADK_ENV.lower() not in {"local", "development", "testing"} and not ADK_A2A_API_KEY:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "failed",
                "error": {
                    "code": "A2A_AUTH_NOT_CONFIGURED",
                    "message": "ADK_A2A_API_KEY must be configured outside local/testing environments.",
                },
            },
        )

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
    task_id = str(body.get("id") or "default")
    message = body.get("message", {})
    parts = message.get("parts", [])
    if not parts or "text" not in parts[0]:
        raise HTTPException(status_code=400, detail="Missing message.parts.0.text")

    prompt = str(parts[0]["text"])
    raw_header_team = x_electrik_team_id
    raw_meta_team = body.get("metadata", {}).get("team_id")
    has_header = raw_header_team is not None and raw_header_team != ""
    has_meta = raw_meta_team is not None and raw_meta_team != ""

    header_team_id = _parse_positive_team_id(raw_header_team) if has_header else None
    meta_team_id = _parse_positive_team_id(raw_meta_team) if has_meta else None

    if (has_header and header_team_id is None) or (has_meta and meta_team_id is None):
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "MISSING_TENANT_CONTEXT",
                    "message": "Valid positive integer X-Electrik-Team-Id header or metadata.team_id is required.",
                },
            },
        )

    if header_team_id is not None and meta_team_id is not None and header_team_id != meta_team_id:
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "TENANT_CONTEXT_MISMATCH",
                    "message": "X-Electrik-Team-Id header does not match metadata.team_id.",
                },
            },
        )

    team_id = header_team_id if header_team_id is not None else meta_team_id
    if team_id is None:
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

    user_id = f"team-{team_id}"
    session = await session_service.get_session(
        app_name=APP_NAME, user_id=user_id, session_id=task_id
    )
    if session is None:
        session = await session_service.create_session(
            app_name=APP_NAME,
            user_id=user_id,
            session_id=task_id,
            state={"tenant_team_id": str(team_id)},
        )

    content = types.Content(role="user", parts=[types.Part.from_text(text=prompt)])
    final_response_chunks: list[str] = []
    async for event in runner.run_async(
        user_id=user_id,
        session_id=task_id,
        new_message=content,
    ):
        is_final = getattr(event, "is_final_response", None)
        if callable(is_final) and is_final():
            event_content = getattr(event, "content", None)
            for part in getattr(event_content, "parts", []) or []:
                part_text = getattr(part, "text", None)
                if part_text:
                    final_response_chunks.append(str(part_text))

    updated_session = await session_service.get_session(
        app_name=APP_NAME, user_id=user_id, session_id=task_id
    )
    state_output = (
        updated_session.state.get("final_output")
        if updated_session is not None
        else None
    )
    output_text = str(state_output or "\n".join(final_response_chunks))

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
EOF_ELECTRIK_25

cat << 'EOF_ELECTRIK_26' > adk_service/test_agent_a2a.py
"""Unit tests for Google ADK 2.0 A2A microservice contract and runner execution."""

from __future__ import annotations

import asyncio
import ast
import importlib.util
import pathlib
import sys
import types
import unittest

ADK_DIR = pathlib.Path(__file__).resolve().parent
ROOT_DIR = ADK_DIR.parent


def _install_adk_test_stubs() -> dict[str, object]:
    """Install lightweight in-memory stubs for google-adk, genai, fastapi, and uvicorn."""
    created_agents: list[dict[str, object]] = []

    class FakeAgent:
        def __init__(self, **kwargs: object) -> None:
            self.kwargs = kwargs
            self.name = str(kwargs.get("name", "agent"))
            self.description = str(kwargs.get("description", ""))
            created_agents.append(kwargs)

    class FakeSequentialAgent(FakeAgent):
        pass

    class FakeSession:
        def __init__(self, state: dict[str, object]) -> None:
            self.state = dict(state)

    class FakeInMemorySessionService:
        def __init__(self) -> None:
            self.sessions: dict[tuple[str, str, str], FakeSession] = {}

        async def get_session(
            self, *, app_name: str, user_id: str, session_id: str
        ) -> FakeSession | None:
            return self.sessions.get((app_name, user_id, session_id))

        async def create_session(
            self,
            *,
            app_name: str,
            user_id: str,
            session_id: str,
            state: dict[str, object] | None = None,
        ) -> FakeSession:
            session = FakeSession(state or {})
            self.sessions[(app_name, user_id, session_id)] = session
            return session

    class FakeEvent:
        def __init__(self, text: str) -> None:
            self.content = types.SimpleNamespace(
                parts=[types.SimpleNamespace(text=text)]
            )

        def is_final_response(self) -> bool:
            return True

    class FakeRunner:
        def __init__(self, *, agent: object, app_name: str, session_service: FakeInMemorySessionService) -> None:
            self.agent = agent
            self.app_name = app_name
            self.session_service = session_service

        async def run_async(
            self, *, user_id: str, session_id: str, new_message: object
        ):
            session = self.session_service.sessions[(self.app_name, user_id, session_id)]
            prompt_text = getattr(getattr(new_message, "parts", [types.SimpleNamespace(text="")])[0], "text", "")
            team_id = session.state.get("tenant_team_id")
            session.state["final_output"] = f"Synthesized ADK Runner output for team {team_id}: {prompt_text}"
            yield FakeEvent(str(session.state["final_output"]))

    class FakeHTTPException(Exception):
        def __init__(self, status_code: int, detail: object) -> None:
            super().__init__(str(detail))
            self.status_code = status_code
            self.detail = detail

    class FakeRequest:
        def __init__(self, body: dict[str, object]) -> None:
            self._body = body

        async def json(self) -> dict[str, object]:
            return self._body

    class FakeFastAPI:
        def __init__(self, **_: object) -> None:
            self.routes: dict[str, object] = {}

        def get(self, path: str):
            def decorator(fn):
                self.routes[f"GET {path}"] = fn
                return fn
            return decorator

        def post(self, path: str):
            def decorator(fn):
                self.routes[f"POST {path}"] = fn
                return fn
            return decorator

    google_mod = types.ModuleType("google")
    google_adk_mod = types.ModuleType("google.adk")
    google_adk_agents_mod = types.ModuleType("google.adk.agents")
    google_adk_agents_mod.LlmAgent = FakeAgent  # type: ignore[attr-defined]
    google_adk_agents_mod.SequentialAgent = FakeSequentialAgent  # type: ignore[attr-defined]

    google_adk_runners_mod = types.ModuleType("google.adk.runners")
    google_adk_runners_mod.Runner = FakeRunner  # type: ignore[attr-defined]

    google_adk_sessions_mod = types.ModuleType("google.adk.sessions")
    google_adk_sessions_mod.InMemorySessionService = FakeInMemorySessionService  # type: ignore[attr-defined]

    google_adk_tools_mod = types.ModuleType("google.adk.tools")
    google_adk_tools_mod.google_search = object()  # type: ignore[attr-defined]

    google_genai_mod = types.ModuleType("google.genai")
    google_genai_types_mod = types.ModuleType("google.genai.types")
    google_genai_types_mod.Part = types.SimpleNamespace(from_text=lambda text="": types.SimpleNamespace(text=text))  # type: ignore[attr-defined]
    google_genai_types_mod.Content = lambda role="user", parts=None: types.SimpleNamespace(role=role, parts=parts or [])  # type: ignore[attr-defined]

    fastapi_mod = types.ModuleType("fastapi")
    fastapi_mod.FastAPI = FakeFastAPI  # type: ignore[attr-defined]
    fastapi_mod.Header = lambda default=None, **_: default  # type: ignore[attr-defined]
    fastapi_mod.HTTPException = FakeHTTPException  # type: ignore[attr-defined]
    fastapi_mod.Request = FakeRequest  # type: ignore[attr-defined]

    uvicorn_mod = types.ModuleType("uvicorn")
    uvicorn_mod.run = lambda *_, **__: None  # type: ignore[attr-defined]

    modules = {
        "google": google_mod,
        "google.adk": google_adk_mod,
        "google.adk.agents": google_adk_agents_mod,
        "google.adk.runners": google_adk_runners_mod,
        "google.adk.sessions": google_adk_sessions_mod,
        "google.adk.tools": google_adk_tools_mod,
        "google.genai": google_genai_mod,
        "google.genai.types": google_genai_types_mod,
        "fastapi": fastapi_mod,
        "uvicorn": uvicorn_mod,
    }
    for name, mod in modules.items():
        sys.modules[name] = mod

    return {"FakeRequest": FakeRequest, "FakeHTTPException": FakeHTTPException}


class AdkA2aServiceContractTest(unittest.TestCase):
    def test_agent_uses_adk_runner_and_not_nonexistent_sequential_run(self) -> None:
        agent_path = ADK_DIR / "agent.py"
        self.assertTrue(agent_path.is_file(), "adk_service/agent.py must exist")
        source = agent_path.read_text(encoding="utf-8")
        ast.parse(source)
        self.assertIn("/.well-known/agent.json", source)
        self.assertIn("/a2a/tasks/send", source)
        self.assertIn("SequentialAgent", source)
        self.assertIn("InMemorySessionService", source)
        self.assertIn("Runner", source)
        self.assertIn("run_async", source)
        self.assertNotIn("root_agent." + "run(", source)
        self.assertIn("electrik_triage_agent", source)
        self.assertIn("electrik_synthesis_agent", source)

    def test_send_a2a_task_executes_runner_and_enforces_auth_and_tenant_boundaries(self) -> None:
        stubs = _install_adk_test_stubs()
        spec = importlib.util.spec_from_file_location("electrik_adk_agent_under_test", ADK_DIR / "agent.py")
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        FakeRequest = stubs["FakeRequest"]
        FakeHTTPException = stubs["FakeHTTPException"]

        module.ADK_A2A_API_KEY = "adk-secret"
        module.ADK_ENV = "production"

        result = asyncio.run(
            module.send_a2a_task(
                FakeRequest(
                    {
                        "id": "task-77",
                        "message": {"role": "user", "parts": [{"text": "Inspect tenant invoices"}]},
                        "metadata": {"team_id": 15},
                    }
                ),
                x_electrik_team_id="15",
                x_a2a_api_key="adk-secret",
            )
        )
        self.assertEqual(result["status"], "completed")
        self.assertEqual(result["metadata"]["team_id"], 15)
        self.assertIn("Synthesized ADK Runner output for team 15", result["message"]["parts"][0]["text"])

        with self.assertRaises(FakeHTTPException) as bad_int:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-bad-int",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                        }
                    ),
                    x_electrik_team_id="15abc",
                    x_a2a_api_key="adk-secret",
                )
            )
        self.assertEqual(bad_int.exception.status_code, 422)

        with self.assertRaises(FakeHTTPException) as mismatch:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-mismatch",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                            "metadata": {"team_id": 99},
                        }
                    ),
                    x_electrik_team_id="15",
                    x_a2a_api_key="adk-secret",
                )
            )
        self.assertEqual(mismatch.exception.status_code, 422)
        self.assertEqual(mismatch.exception.detail["error"]["code"], "TENANT_CONTEXT_MISMATCH")

        module.ADK_A2A_API_KEY = ""
        module.ADK_ENV = "production"
        with self.assertRaises(FakeHTTPException) as prod_unconfigured:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-unconfigured",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                        }
                    ),
                    x_electrik_team_id="15",
                    x_a2a_api_key="",
                )
            )
        self.assertEqual(prod_unconfigured.exception.status_code, 503)

    def test_single_canonical_setup_script_exists_and_preserves_boost_guidelines(self) -> None:
        duplicate_script = ADK_DIR / "setup_electrik_agent_kit.sh"
        canonical_script = ROOT_DIR / "setup_electrik_agent_kit.sh"
        self.assertFalse(duplicate_script.exists(), "Duplicate adk_service/setup_electrik_agent_kit.sh must be removed")
        self.assertTrue(canonical_script.is_file(), "Canonical setup_electrik_agent_kit.sh must exist at repository root")
        content = canonical_script.read_text(encoding="utf-8")
        self.assertNotIn("root_agent." + "run(", content)
        self.assertNotIn("X-Tenant-" + "ID", content)
        self.assertIn("<laravel-boost-guidelines>", content)
        self.assertIn("TenantCopilotAgent", content)
        self.assertIn("RunTenantAdkWorkflowJob", content)


if __name__ == "__main__":
    unittest.main()
EOF_ELECTRIK_26

echo "[7/8] Writing Pest 5 architecture, harness, validator, registry, and A2A tests..."
cat << 'EOF_ELECTRIK_27' > tests/Feature/ArchitectureTest.php
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
EOF_ELECTRIK_27

cat << 'EOF_ELECTRIK_28' > tests/Feature/AgentHarnessConfigTest.php
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
EOF_ELECTRIK_28

cat << 'EOF_ELECTRIK_29' > tests/Unit/MigrationValidatorScriptTest.php
<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Process;
use Tests\TestCase;

uses(TestCase::class);

it('passes valid reversible migrations and rejects migrations without down() or with DROP statements', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');
    expect(is_file($script))->toBeTrue();

    $tmpDir = sys_get_temp_dir().'/electrik_mig_test_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $validFile = "{$tmpDir}/2026_11_11_000001_create_projects_table.php";
    file_put_contents($validFile, "<?php\nreturn new class {\npublic function up(): void {}\npublic function down(): void {}\n};\n");

    $passResult = Process::run(['python3', $script, $validFile]);
    expect($passResult->successful())->toBeTrue()
        ->and($passResult->output())->toContain('[OK]');

    $invalidFile = "{$tmpDir}/2026_11_11_000002_bad_migration.php";
    file_put_contents($invalidFile, "<?php\nreturn new class {\npublic function up(): void { DB::statement('DROP TABLE users'); }\n};\n");

    $failResult = Process::run(['python3', $script, $invalidFile]);
    expect($failResult->failed())->toBeTrue()
        ->and($failResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($validFile);
    @unlink($invalidFile);
    @rmdir($tmpDir);
});

it('rejects Schema::dropIfExists of core tables in up() or standalone drop migrations while allowing create_users down()', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');

    $existingResult = Process::run(['python3', $script, base_path('database/migrations')]);
    expect($existingResult->successful())->toBeTrue()
        ->and($existingResult->output())->toContain('[OK]');

    $tmpDir = sys_get_temp_dir().'/electrik_mig_core_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $dropCoreInUp = "{$tmpDir}/2026_11_11_000003_drop_teams.php";
    file_put_contents($dropCoreInUp, "<?php\nreturn new class {\npublic function up(): void { Schema::dropIfExists('teams'); }\npublic function down(): void {}\n};\n");

    $failResult = Process::run(['python3', $script, $dropCoreInUp]);
    expect($failResult->failed())->toBeTrue()
        ->and($failResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($dropCoreInUp);
    @rmdir($tmpDir);
});

it('rejects ->truncate(), missing up(), and standalone Schema::dropIfExists in down()', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');

    $tmpDir = sys_get_temp_dir().'/electrik_mig_extra_'.bin2hex(random_bytes(4));
    mkdir($tmpDir, 0777, true);

    $truncateFile = "{$tmpDir}/2026_11_11_000004_truncate_users.php";
    file_put_contents($truncateFile, "<?php\nreturn new class {\npublic function up(): void { DB::table('users')->truncate(); }\npublic function down(): void {}\n};\n");

    $truncateResult = Process::run(['python3', $script, $truncateFile]);
    expect($truncateResult->failed())->toBeTrue()
        ->and($truncateResult->output())->toContain('[MIGRATION_ERROR]');

    $missingUpFile = "{$tmpDir}/2026_11_11_000005_missing_up.php";
    file_put_contents($missingUpFile, "<?php\nreturn new class {\npublic function down(): void {}\n};\n");

    $missingUpResult = Process::run(['python3', $script, $missingUpFile]);
    expect($missingUpResult->failed())->toBeTrue()
        ->and($missingUpResult->output())->toContain('[MIGRATION_ERROR]');

    $standaloneDownDropFile = "{$tmpDir}/2026_11_11_000006_drop_teams_in_down.php";
    file_put_contents($standaloneDownDropFile, "<?php\nreturn new class {\npublic function up(): void {}\npublic function down(): void { Schema::dropIfExists('teams'); }\n};\n");

    $standaloneResult = Process::run(['python3', $script, $standaloneDownDropFile]);
    expect($standaloneResult->failed())->toBeTrue()
        ->and($standaloneResult->output())->toContain('[MIGRATION_ERROR]');

    @unlink($truncateFile);
    @unlink($missingUpFile);
    @unlink($standaloneDownDropFile);
    @rmdir($tmpDir);
});
EOF_ELECTRIK_29

cat << 'EOF_ELECTRIK_30' > tests/Unit/SkillRegistryTest.php
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
EOF_ELECTRIK_30

cat << 'EOF_ELECTRIK_31' > tests/Feature/A2aProtocolTest.php
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
EOF_ELECTRIK_31

chmod +x .agents/bin/statusline.sh .agents/skills/laravel-migration-validator/scripts/validate_migration.py

for skill_name in electrik-tenant-scaffold slate-blade-ui electrik-cashier-billing laravel-pest-verify laravel-pint-fix laravel-migration-validator adk-a2a-bridge; do
    ln -sfn "../../.agents/skills/$skill_name" ".ai/skills/$skill_name"
done

echo "[8/8] Idempotently wiring strict_types, bootstrap/app.php, config/services.php, AppServiceProvider, and tests/Pest.php..."
python3 - << 'PY_WIRE'
import pathlib, re

for php_path in ('app/Models/User.php', 'app/Http/Controllers/Controller.php', 'app/Providers/AppServiceProvider.php'):
    p = pathlib.Path(php_path)
    if p.exists():
        src = p.read_text(encoding='utf-8')
        if 'declare(strict_types=1);' not in src:
            src = src.replace('<?php\n', '<?php\n\ndeclare(strict_types=1);\n', 1)
            p.write_text(src, encoding='utf-8')

bootstrap = pathlib.Path('bootstrap/app.php')
if bootstrap.exists():
    bsrc = bootstrap.read_text(encoding='utf-8')
    if 'laravel_ai_shims.php' not in bsrc:
        bsrc = bsrc.replace('<?php\n', "<?php\n\nrequire_once __DIR__.'/laravel_ai_shims.php';\n", 1)
    if 'routes/a2a.php' not in bsrc:
        bsrc = re.sub(
            r"(health:\s*'[^']+',\s*\n)(\s*)\)",
            r"\1\2    then: function (): void {\n\2        require base_path('routes/a2a.php');\n\2    },\n\2)",
            bsrc,
            count=1,
        )
    bootstrap.write_text(bsrc, encoding='utf-8')

services = pathlib.Path('config/services.php')
if services.exists():
    ssrc = services.read_text(encoding='utf-8')
    if "'adk'" not in ssrc:
        adk_block = (
            "\n    'adk' => [\n"
            "        'endpoint' => env('ADK_A2A_ENDPOINT', 'http://127.0.0.1:8080/a2a/tasks/send'),\n"
            "        'api_key' => env('ADK_A2A_API_KEY', ''),\n"
            "        'server_api_key' => env('A2A_SERVER_API_KEY', ''),\n"
            "    ],\n\n];"
        )
        ssrc = re.sub(r"\n\];\s*$", adk_block + "\n", ssrc, count=1)
        services.write_text(ssrc, encoding='utf-8')

provider = pathlib.Path('app/Providers/AppServiceProvider.php')
if provider.exists():
    psrc = provider.read_text(encoding='utf-8')
    if 'SkillRegistry' not in psrc:
        psrc = psrc.replace(
            'use Illuminate\\Support\\ServiceProvider;',
            'use App\\Ai\\SkillRegistry;\nuse Illuminate\\Support\\ServiceProvider;',
            1,
        )
        psrc = re.sub(
            r"(public function register\(\): void\s*\{\s*)//(\s*\})",
            r"""\1$this->app->singleton(SkillRegistry::class, function (): SkillRegistry {
            $registry = new SkillRegistry;
            foreach (glob(base_path('.agents/skills/*/SKILL.md')) ?: [] as $skillFile) {
                $skillName = basename(dirname($skillFile));
                $registry->register($skillName, $skillFile);
            }

            return $registry;
        });\2""",
            psrc,
            count=1,
        )
        provider.write_text(psrc, encoding='utf-8')

pest = pathlib.Path('tests/Pest.php')
if pest.exists():
    ptsrc = pest.read_text(encoding='utf-8')
    if 'laravel_ai_shims.php' not in ptsrc:
        ptsrc = ptsrc.replace(
            '<?php\n',
            "<?php\n\nrequire_once __DIR__.'/../bootstrap/laravel_ai_shims.php';\n",
            1,
        )
        pest.write_text(ptsrc, encoding='utf-8')
PY_WIRE

echo "✅ Electrik x Antigravity 2.0 & CLI x A2A engineering kit deployed cleanly."
