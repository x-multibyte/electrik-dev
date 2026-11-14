# Electrik Laravel 13 SaaS × Antigravity 2.0 & CLI × Google ADK 2.0 (A2A) Implementation Plan

> **For Agentic Workers:** REQUIRED: Use [Antigravity 2.0](https://antigravity.google/docs/overview/) or [Antigravity CLI (`agy`)](https://antigravity.google/docs/cli/overview/) micro-transaction workflows (`user:subagent-driven-development` or `user:executing-plans`) to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. After completing each task's commit step, run `/clear` in Antigravity CLI to reset context before starting the next task.

**Goal:** Build the complete AI Agent engineering infrastructure, security sandbox, MCP introspection bus, progressive-disclosure skills, and bidirectional Agent2Agent (A2A) protocol bridge connecting an [Electrik (`electrik/electrik` ^5.5)](https://github.com/electrikhq/electrik) multi-tenant Laravel 13 SaaS application with [Laravel Boost](https://laravel.com/framework/docs/13.x/boost), [Laravel AI SDK](https://laravel.com/framework/docs/ai-sdk), and [Google ADK 2.0](https://adk.dev/2.0/).

**Architecture:**
1. **SaaS Core & UI Shell**: Keep authentication, team management, Stripe Cashier billing, and `/ops` encapsulated inside `vendor/electrik/electrik` (`Electrik\` namespace), while building tenant-scoped business features in `App\` using `BelongsToTeam` models and [Electrik Slate 3 (`<x-slate::*>`)](https://github.com/electrikhq/slate) anonymous Blade components on Livewire 4 and Tailwind CSS v4.
2. **Agent Harness & Context Layer**: Enforce deterministic file/command boundaries via [Antigravity CLI `.gemini/settings.json`](https://antigravity.google/docs/cli/permissions/) (`Deny > Ask > Allow` + `enableTerminalSandbox: true`), expose live schema/docs/component introspection via [Laravel Boost MCP](https://laravel.com/framework/docs/13.x/boost) and [Slate MCP](https://slate.electrik.dev/docs/ai) in `.agents/mcp_config.json`, and scope directory-level conventions in `.ai/rules/` and on-demand skills in `.agents/skills/` (symlinked to `.ai/skills/`).
3. **Bidirectional A2A Runtime Bridge**: Since [Laravel AI SDK](https://laravel.com/framework/docs/ai-sdk) natively supports MCP but does not bundle the [Agent2Agent (A2A) protocol](https://github.com/google-a2a/a2a-python), this plan implements a production-grade bidirectional A2A adapter (`App\Ai\A2a\A2aServerController`, `App\Ai\A2a\RemoteAdkAgentTool`, and `App\Jobs\RunTenantAdkWorkflowJob`) paired with a [Google ADK 2.0 Python](https://github.com/google/adk-python) `SequentialAgent` microservice (`adk_service/agent.py`) and Stripe Cashier team token metering.

**Tech Stack:** PHP 8.4+, [Laravel 13.x](https://laravel.com/framework/docs/installation), [Electrik `^5.5` (MIT)](https://github.com/electrikhq/electrik), [Electrik Slate `^3.0`](https://github.com/electrikhq/slate), [Livewire 4](https://livewire.laravel.com/), [Tailwind CSS v4](https://slate.electrik.dev/), [Laravel Cashier Stripe `^15.0`](https://laravel.com/framework/docs/billing), [Spatie Permission `^6.0`](https://github.com/electrikhq/electrik), [Laravel Boost `^2.10`](https://github.com/laravel/boost), [Laravel AI SDK (`laravel/ai`)](https://github.com/laravel/ai), Pest 5, Laravel Pint, [Google Antigravity 2.0 & CLI (`agy`)](https://antigravity.google/docs/home/), Python 3.12+, [Google ADK 2.0 (`google-adk`)](https://adk.dev/2.0/), FastAPI.

## 1. Cross-System Architecture & Technology Baseline

| Architectural Layer | Core Component & Version | Operational Responsibility & Agent Guardrails |
| :--- | :--- | :--- |
| **Runtime & Framework** | PHP 8.4+ / [Laravel 13.x](https://laravel.com/framework/docs/installation) | Single-entry `bootstrap/app.php` topology (no `app/Http/Kernel.php`); PHP 8.4 Property Hooks, Asymmetric Visibility (`public private(set)`), and model `casts(): array` method. |
| **SaaS Shell** | [Electrik `^5.5` (MIT)](https://github.com/electrikhq/electrik) | Vendor-isolated `Electrik\` namespace for auth, teams, Stripe Cashier billing, onboarding, and `/ops` console; customize via `config/electrik.php` and `ELECTRIK_*` env flags. |
| **Reactive Frontend & UI** | [Livewire 4](https://livewire.laravel.com/) + [Electrik Slate 3 (`^3.0`)](https://github.com/electrikhq/slate) | Anonymous `<x-slate::*>` Blade primitives and [`<x-slate-block::*>`](https://slate.electrik.dev/blocks) marketing blocks styled with Tailwind CSS v4 tokens (`--slate-*`); zero React/Vue/Inertia/shadcn imports. |
| **Multi-Tenancy & RBAC** | [Electrik Teamwork (`^11.0`)](https://github.com/electrikhq/teamwork) + Spatie Permission (`^6.0`) | Team is the primary security and data boundary; scaffold tenant models with `php artisan electrik:make:model` so `BelongsToTeam` and team-scoped policies are wired automatically. |
| **Subscription & Metered Billing** | [Laravel Cashier Stripe (`^15.0`)](https://laravel.com/framework/docs/billing) | Subscriptions, plans, add-ons, and metered AI token usage bind directly to the `Team` model (`$user->currentTeam`), synced via `php artisan electrik:stripe:sync`. |
| **Primary AI Dev Toolchain** | [Antigravity 2.0 (v2.13+)](https://antigravity.google/docs/overview/) & [Antigravity CLI (v1.2+)](https://antigravity.google/docs/cli/overview/) | [Gemini 3.8 Flash](https://antigravity.google/blog/gemini-3-8-flash-in-google-antigravity) workhorse + `/boost` deep reasoning; [Planning Mode Artifacts](https://antigravity.google/docs/artifacts/) review; OS sandbox isolation and `/clear` micro-transactions. |
| **Introspection & Context Bus** | [Laravel Boost (`v2.10+`)](https://laravel.com/framework/docs/13.x/boost) + [Slate MCP](https://slate.electrik.dev/docs/ai) | Stdio MCP servers providing `application-info`, `database-schema`, read-only `database-query`, `last-error`, `search-docs` (17,000+ chunks), `record-rule`, and Slate UI specs. |
| **In-App AI & Multi-Agent Bridge** | [Laravel AI SDK](https://laravel.com/framework/docs/ai-sdk) + [Google ADK 2.0](https://adk.dev/2.0/) | In-app PHP agents reuse `.ai/skills/` via `App\Ai\SkillRegistry` and communicate bidirectionally with Python [Google ADK 2.0](https://adk.dev/get-started/about/) `SequentialAgent` clusters over the [A2A protocol](https://github.com/google-a2a/a2a-python). |

## 2. File Structure & Responsibility Map

Every file created or modified in this implementation plan is scoped to a single, well-defined responsibility:

### 2.1 Agent Harness, Security Firewall & MCP Configuration
- `AGENTS.md`: Top-level machine instruction constitution referencing canonical LLM endpoints ([`https://electrik.dev/llms.txt`](https://electrik.dev/llms.txt), [`https://electrik.dev/llms-full.txt`](https://electrik.dev/llms-full.txt), [`https://slate.electrik.dev/llms.txt`](https://slate.electrik.dev/llms.txt), [`https://slate.electrik.dev/llms-full.txt`](https://slate.electrik.dev/llms-full.txt)) while preserving the `<laravel-boost-guidelines>` block.
- `.gemini/settings.json`: [Antigravity CLI permission firewall](https://antigravity.google/docs/cli/permissions/) enforcing `Deny > Ask > Allow` monotonicity, enabling `enableTerminalSandbox`, allowing safe generators/tests/MCP introspection, and blocking `.env*`, `vendor/`, and unapproved abstraction directories (`app/Services/`, `app/Repositories/`, `app/Actions/`).
- `.agents/mcp_config.json`: Project-local MCP registry mounting `laravel-boost` (`php artisan boost:mcp`) and `electrik-slate` (`npx -y @electrik/slate-mcp`).
- `.agents/bin/statusline.sh`: Executable status line script for [Antigravity CLI TUI](https://antigravity.google/docs/cli/statusline/) displaying active Git branch, Sandbox state, and A2A/Boost readiness.

### 2.2 Laravel Boost Project Rules & Custom Guidelines
- `.ai/rules/index.md`: Entry table of contents mapping directory globs to specific convention files.
- `.ai/rules/electrik-package-boundary.md`: Rules for `config/**`, `routes/**`, `app/Providers/**` protecting `Electrik\` vendor encapsulation and integer-cents currency conventions.
- `.ai/rules/team-tenancy-models.md`: Rules for `app/Models/**` and `database/migrations/**` enforcing `BelongsToTeam`, `team_id` foreign keys, `casts(): array`, and PHP 8.4 asymmetric visibility.
- `.ai/rules/slate-livewire-views.md`: Rules for `resources/views/**` and `app/Livewire/**` enforcing `<x-slate::*>` components, Tailwind CSS v4 tokens, dark mode, and 5-locale (`en`, `es`, `fr`, `ar` RTL, `hi`) i18n support.
- `.ai/rules/controllers-and-requests.md`: Rules for `app/Http/**` enforcing thin controllers, FormRequest validation, Spatie team permission checks, and queued jobs.
- `.ai/guidelines/electrik-core.md`: Upfront [Laravel Boost guideline](https://laravel.com/framework/docs/13.x/boost) loaded at session initialization.

### 2.3 Progressive-Disclosure Workspace Skills (`.agents/skills/` & `.ai/skills/`)
- `.agents/skills/electrik-tenant-scaffold/SKILL.md`: Workflow for `php artisan electrik:make:model` and `electrik:make:resource` with `BelongsToTeam` and cross-tenant Pest tests.
- `.agents/skills/slate-blade-ui/SKILL.md`: Workflow for building Livewire 4 UI views with `<x-slate::*>` and `<x-slate-block::*>` primitives.
- `.agents/skills/electrik-cashier-billing/SKILL.md`: Workflow for Team-level Stripe Cashier billing, metered usage reporting, and `php artisan electrik:stripe:sync`.
- `.agents/skills/laravel-pest-verify/SKILL.md`: Red-Green-Refactor TDD workflow and code-review severity checklist.
- `.agents/skills/laravel-pint-fix/SKILL.md`: Dirty-file formatting workflow (`vendor/bin/pint --dirty --format agent`).
- `.agents/skills/laravel-migration-validator/SKILL.md` & `.agents/skills/laravel-migration-validator/scripts/validate_migration.py`: Deterministic Python validator checking `up()`, `down()`, and blocking destructive SQL in migrations.
- `.agents/skills/adk-a2a-bridge/SKILL.md`: Workflow for bridging [Laravel AI SDK](https://laravel.com/framework/docs/ai-sdk) and [Google ADK 2.0](https://adk.dev/2.0/) over A2A.
- `.ai/skills/*`: Symbolic links to `.agents/skills/*` so both coding agents (Antigravity/Boost) and runtime PHP agents (`App\Ai\SkillRegistry`) share a single source of truth.

### 2.4 Application Runtime AI & Bidirectional A2A Protocol Layer
- `config/services.php` & `bootstrap/app.php`: Registers `services.adk` configuration (`endpoint`, `api_key`) and mounts `routes/a2a.php`.
- `app/Ai/SkillRegistry.php`: Runtime loader that strips YAML frontmatter from `.ai/skills/<name>/SKILL.md` and injects task-specific instructions into Laravel AI SDK agents on demand.
- `app/Ai/Agents/TenantCopilotAgent.php`: Tenant-scoped [Laravel AI SDK](https://laravel.com/framework/docs/ai-sdk) agent implementing `Agent` and `HasTools`, equipped with `RemoteAdkAgentTool`.
- `app/Ai/A2a/A2aServerController.php`: Laravel A2A Server exposing `GET /.well-known/agent.json` (`agentCard`) and `POST /api/a2a/tasks/send` (`handleTask`) with mandatory `X-Electrik-Team-Id` / `metadata.team_id` validation and optional `X-A2A-Api-Key` verification.
- `app/Ai/A2a/RemoteAdkAgentTool.php`: Laravel AI SDK `Tool` implementation acting as an A2A Client to delegate complex multi-step reasoning to the Google ADK 2.0 service.
- `app/Jobs/RunTenantAdkWorkflowJob.php`: Queued job (`ShouldQueue`) that loads a skill from `SkillRegistry`, dispatches an A2A task to `adk_service`, and reports consumed token usage to the active Electrik `Team` Cashier subscription.
- `routes/a2a.php`: Dedicated route file for `/.well-known/agent.json` and `/api/a2a/tasks/send`.
- `adk_service/agent.py` & `adk_service/requirements.txt`: Python [Google ADK 2.0](https://adk.dev/2.0/) `SequentialAgent` (`electrik_triage_agent` -> `electrik_synthesis_agent`) exposed via FastAPI A2A endpoints (`/.well-known/agent.json` and `/a2a/tasks/send`).

### 2.5 Automated Contract & Architecture Test Suite
- `tests/Feature/ArchitectureTest.php`: Pest 5 architectural gate blocking `dd`/`dump`, enforcing `declare(strict_types=1)`, and asserting `App\Services`, `App\Repositories`, and `App\Actions` remain empty.
- `tests/Feature/AgentHarnessConfigTest.php`: Verifies `.gemini/settings.json` monotonicity rules, `.agents/mcp_config.json` servers, `AGENTS.md` endpoints, and `.ai/rules/index.md` integrity.
- `tests/Unit/MigrationValidatorScriptTest.php`: Verifies `validate_migration.py` passes valid reversible migrations and rejects migrations missing `down()` or containing destructive drops.
- `tests/Unit/SkillRegistryTest.php`: Verifies `App\Ai\SkillRegistry` loads `.ai/skills/*/SKILL.md` and strips YAML frontmatter cleanly.
- `tests/Feature/A2aProtocolTest.php`: Verifies `GET /.well-known/agent.json`, `POST /api/a2a/tasks/send` tenant context enforcement (`422`), API key authentication (`401`), `RemoteAdkAgentTool` A2A client calls, and `RunTenantAdkWorkflowJob` execution.

## 3. Bite-Sized TDD Implementation Tasks

### Task 1: Bootstrap Electrik Laravel 13 Baseline & Pest 5 Architecture Gate

**Files:**
- Modify: `composer.json` (require `electrik/electrik:^5.5`, `laravel/ai`, `laravel/boost` dev)
- Create: `tests/Feature/ArchitectureTest.php`

- [ ] **Step 1: Write the failing Pest architecture test**

Create `tests/Feature/ArchitectureTest.php`:

```php
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
    ->toBeEmpty();

arch('controllers follow naming and cohesion conventions')
    ->expect('App\Http\Controllers')
    ->toHaveSuffix('Controller');
```

- [ ] **Step 2: Run Pest to verify baseline check**

Run:
```bash
vendor/bin/pest tests/Feature/ArchitectureTest.php
```
Expected: If any starter file in `app/` lacks `declare(strict_types=1);`, Pest fails and lists the file line.

- [ ] **Step 3: Add `declare(strict_types=1);` to existing `app/` files and configure `composer.json` `post-update-cmd`**

Ensure `app/Models/User.php`, `app/Providers/AppServiceProvider.php`, and `app/Http/Controllers/Controller.php` declare `strict_types=1`, and register `@php artisan boost:update --ansi` in `composer.json` scripts.

- [ ] **Step 4: Re-run the architecture test to verify Green**

Run:
```bash
vendor/bin/pest tests/Feature/ArchitectureTest.php
```
Expected: PASS (`5 passed`).

- [ ] **Step 5: Format and commit**

Run:
```bash
vendor/bin/pint --dirty --format agent
git add tests/Feature/ArchitectureTest.php app/ composer.json
git commit -m "test(arch): enforce Laravel 13 strict types and block unapproved abstraction layers"
```

### Task 2: Configure Antigravity 2.0 & CLI Permission Firewall, Sandbox & MCP Bus

**Files:**
- Create: `tests/Feature/AgentHarnessConfigTest.php`
- Create: `AGENTS.md`
- Create: `.gemini/settings.json`
- Create: `.agents/mcp_config.json`
- Create: `.agents/bin/statusline.sh`

- [ ] **Step 1: Write the failing test verifying Antigravity and MCP configuration contracts**

Create `tests/Feature/AgentHarnessConfigTest.php`:

```php
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
```

- [ ] **Step 2: Run Pest to verify the test fails**

Run:
```bash
vendor/bin/pest tests/Feature/AgentHarnessConfigTest.php
```
Expected: FAIL (`Failed asserting that false is true` because `.gemini/settings.json`, `.agents/mcp_config.json`, and `AGENTS.md` do not exist yet).

- [ ] **Step 3: Create `AGENTS.md`, `.gemini/settings.json`, `.agents/mcp_config.json`, and `.agents/bin/statusline.sh`**

Write `AGENTS.md` (with the 5 architectural invariants and `<laravel-boost-guidelines>` block), `.gemini/settings.json` (with `enableTerminalSandbox: true` and full `allow`/`deny`/`ask` arrays), `.agents/mcp_config.json`, and `.agents/bin/statusline.sh` (`chmod +x`).

- [ ] **Step 4: Run Pest to verify the test passes**

Run:
```bash
vendor/bin/pest tests/Feature/AgentHarnessConfigTest.php
```
Expected: PASS (`3 passed`).

- [ ] **Step 5: Commit**

Run:
```bash
git add AGENTS.md .gemini/settings.json .agents/mcp_config.json .agents/bin/statusline.sh tests/Feature/AgentHarnessConfigTest.php
git commit -m "chore(agent): configure Antigravity CLI sandbox permissions, MCP servers, and AGENTS.md"
```

### Task 3: Establish Laravel Boost Project Rules (`.ai/rules/`) & Custom Guidelines

**Files:**
- Modify: `tests/Feature/AgentHarnessConfigTest.php`
- Create: `.ai/rules/index.md`
- Create: `.ai/rules/electrik-package-boundary.md`
- Create: `.ai/rules/team-tenancy-models.md`
- Create: `.ai/rules/slate-livewire-views.md`
- Create: `.ai/rules/controllers-and-requests.md`
- Create: `.ai/guidelines/electrik-core.md`

- [ ] **Step 1: Add failing test assertion for `.ai/rules/` path-scoped files**

Append to `tests/Feature/AgentHarnessConfigTest.php`:

```php
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
```

- [ ] **Step 2: Run Pest to verify failure**

Run:
```bash
vendor/bin/pest tests/Feature/AgentHarnessConfigTest.php
```
Expected: FAIL (`Failed asserting that false is true` for `.ai/rules/index.md`).

- [ ] **Step 3: Write the `.ai/rules/*.md` files and `.ai/guidelines/electrik-core.md`**

Create `.ai/rules/index.md` and the 4 path-scoped rule files (`electrik-package-boundary.md`, `team-tenancy-models.md`, `slate-livewire-views.md`, `controllers-and-requests.md`) along with `.ai/guidelines/electrik-core.md` as specified in Section 7 of `Electrik_Antigravity_AI_Agent_Kit.md`.

- [ ] **Step 4: Run Pest to verify Green**

Run:
```bash
vendor/bin/pest tests/Feature/AgentHarnessConfigTest.php
```
Expected: PASS (`4 passed`).

- [ ] **Step 5: Commit**

Run:
```bash
git add .ai/rules/ .ai/guidelines/ tests/Feature/AgentHarnessConfigTest.php
git commit -m "docs(rules): add path-scoped Laravel Boost project rules for Electrik and Slate 3"
```

### Task 4: Package Progressive-Disclosure Workspace Skills & Deterministic Migration Validator

**Files:**
- Create: `tests/Unit/MigrationValidatorScriptTest.php`
- Create: `.agents/skills/electrik-tenant-scaffold/SKILL.md`
- Create: `.agents/skills/slate-blade-ui/SKILL.md`
- Create: `.agents/skills/electrik-cashier-billing/SKILL.md`
- Create: `.agents/skills/laravel-pest-verify/SKILL.md`
- Create: `.agents/skills/laravel-pint-fix/SKILL.md`
- Create: `.agents/skills/laravel-migration-validator/SKILL.md`
- Create: `.agents/skills/laravel-migration-validator/scripts/validate_migration.py`
- Create: `.agents/skills/adk-a2a-bridge/SKILL.md`
- Create: `.ai/skills/*` (symlinks to `.agents/skills/*`)

- [ ] **Step 1: Write the failing unit test for the migration validator script and skill frontmatter**

Create `tests/Unit/MigrationValidatorScriptTest.php`:

```php
<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Process;

it('passes valid reversible migrations and rejects migrations without down() or with DROP statements', function () {
    $script = base_path('.agents/skills/laravel-migration-validator/scripts/validate_migration.py');
    expect(is_file($script))->toBeTrue();

    $tmpDir = sys_get_temp_dir().'/electrik_mig_test_'. uniqid();
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
```

- [ ] **Step 2: Run Pest to verify failure**

Run:
```bash
vendor/bin/pest tests/Unit/MigrationValidatorScriptTest.php
```
Expected: FAIL (`Failed asserting that false is true` because `validate_migration.py` does not exist yet).

- [ ] **Step 3: Create all 7 `.agents/skills/*/SKILL.md` files, `validate_migration.py`, and `.ai/skills/` symlinks**

Write the 7 `SKILL.md` files and `.agents/skills/laravel-migration-validator/scripts/validate_migration.py` (`chmod +x`), then symlink each folder inside `.ai/skills/`.

- [ ] **Step 4: Run Pest to verify Green**

Run:
```bash
vendor/bin/pest tests/Unit/MigrationValidatorScriptTest.php
```
Expected: PASS (`1 passed`).

- [ ] **Step 5: Commit**

Run:
```bash
git add .agents/skills/ .ai/skills/ tests/Unit/MigrationValidatorScriptTest.php
git commit -m "feat(skills): add 7 progressive-disclosure workspace skills and migration validator"
```

### Task 5: Implement Runtime `SkillRegistry` & `TenantCopilotAgent` (`Laravel AI SDK`)

**Files:**
- Create: `tests/Unit/SkillRegistryTest.php`
- Create: `app/Ai/SkillRegistry.php`
- Create: `app/Ai/Agents/TenantCopilotAgent.php`
- Modify: `app/Providers/AppServiceProvider.php`

- [ ] **Step 1: Write the failing unit test for `App\Ai\SkillRegistry`**

Create `tests/Unit/SkillRegistryTest.php`:

```php
<?php

declare(strict_types=1);

use App\Ai\SkillRegistry;

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
```

- [ ] **Step 2: Run Pest to verify failure**

Run:
```bash
vendor/bin/pest tests/Unit/SkillRegistryTest.php
```
Expected: FAIL (`Class "App\Ai\SkillRegistry" not found`).

- [ ] **Step 3: Implement `app/Ai/SkillRegistry.php`, `app/Ai/Agents/TenantCopilotAgent.php`, and bind in `AppServiceProvider`**

Create `app/Ai/SkillRegistry.php`:

```php
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
```

Create `app/Ai/Agents/TenantCopilotAgent.php`:

```php
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

    public function instructions(): Stringable|string
    {
        $registry = app(SkillRegistry::class);

        return "You are the tenant-scoped Electrik SaaS Copilot for Team ID {$this->teamId}.\n\n"
            .$registry->load($this->skillName);
    }

    public function tools(): iterable
    {
        return [
            new RemoteAdkAgentTool(teamId: $this->teamId),
        ];
    }
}
```

Register `SkillRegistry` as a singleton in `app/Providers/AppServiceProvider.php`:

```php
use App\Ai\SkillRegistry;

public function register(): void
{
    $this->app->singleton(SkillRegistry::class, function () {
        $registry = new SkillRegistry;
        foreach (glob(base_path('.agents/skills/*/SKILL.md')) ?: [] as $skillFile) {
            $skillName = basename(dirname($skillFile));
            $registry->register($skillName, $skillFile);
        }

        return $registry;
    });
}
```

- [ ] **Step 4: Run Pest to verify Green**

Run:
```bash
vendor/bin/pest tests/Unit/SkillRegistryTest.php
```
Expected: PASS (`2 passed`).

- [ ] **Step 5: Format and commit**

Run:
```bash
vendor/bin/pint --dirty --format agent
git add app/Ai/SkillRegistry.php app/Ai/Agents/TenantCopilotAgent.php app/Providers/AppServiceProvider.php tests/Unit/SkillRegistryTest.php
git commit -m "feat(ai): implement runtime SkillRegistry and TenantCopilotAgent"
```

### Task 6: Implement Laravel A2A Server Discovery (`/.well-known/agent.json`) & Tenant Task Endpoint

**Files:**
- Create: `tests/Feature/A2aProtocolTest.php`
- Create: `app/Ai/A2a/A2aServerController.php`
- Create: `routes/a2a.php`
- Modify: `bootstrap/app.php` (mount `routes/a2a.php`)
- Modify: `config/services.php` (add `adk` config block)

- [ ] **Step 1: Write the failing Pest feature tests for the A2A Server endpoints**

Create `tests/Feature/A2aProtocolTest.php`:

```php
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
```

- [ ] **Step 2: Run Pest to verify failure**

Run:
```bash
vendor/bin/pest tests/Feature/A2aProtocolTest.php
```
Expected: FAIL (`Expected response status code [200] but received 404`).

- [ ] **Step 3: Implement `app/Ai/A2a/A2aServerController.php`, `routes/a2a.php`, and wire in `bootstrap/app.php` & `config/services.php`**

Create `app/Ai/A2a/A2aServerController.php`:

```php
<?php

declare(strict_types=1);

namespace App\Ai\A2a;

use App\Ai\Agents\TenantCopilotAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

final class A2aServerController
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

        $agent = new TenantCopilotAgent($teamId);
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
```

Create `routes/a2a.php` and register it via the `then:` callback in `bootstrap/app.php` (`withRouting(..., then: function () { require base_path('routes/a2a.php'); })`). Add `'adk' => ['endpoint' => env('ADK_A2A_ENDPOINT', 'http://127.0.0.1:8080/a2a/tasks/send'), 'api_key' => env('ADK_A2A_API_KEY', ''), 'server_api_key' => env('A2A_SERVER_API_KEY', '')]` to `config/services.php`.

- [ ] **Step 4: Run Pest to verify Green**

Run:
```bash
vendor/bin/pest tests/Feature/A2aProtocolTest.php
```
Expected: PASS (`3 passed`).

- [ ] **Step 5: Format and commit**

Run:
```bash
vendor/bin/pint --dirty --format agent
git add app/Ai/A2a/A2aServerController.php routes/a2a.php bootstrap/app.php config/services.php tests/Feature/A2aProtocolTest.php
git commit -m "feat(a2a): implement Laravel A2A Server discovery and tenant-scoped task endpoint"
```

### Task 7: Implement Laravel A2A Client Tool (`RemoteAdkAgentTool`) & Metered Cashier Queued Job

**Files:**
- Modify: `tests/Feature/A2aProtocolTest.php`
- Create: `app/Ai/A2a/RemoteAdkAgentTool.php`
- Create: `app/Jobs/RunTenantAdkWorkflowJob.php`

- [ ] **Step 1: Add failing Pest tests for `RemoteAdkAgentTool` and `RunTenantAdkWorkflowJob`**

Append to `tests/Feature/A2aProtocolTest.php`:

```php
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
```

- [ ] **Step 2: Run Pest to verify failure**

Run:
```bash
vendor/bin/pest tests/Feature/A2aProtocolTest.php
```
Expected: FAIL (`Class "App\Ai\A2a\RemoteAdkAgentTool" not found`).

- [ ] **Step 3: Implement `app/Ai/A2a/RemoteAdkAgentTool.php` and `app/Jobs/RunTenantAdkWorkflowJob.php`**

Write `app/Ai/A2a/RemoteAdkAgentTool.php` and `app/Jobs/RunTenantAdkWorkflowJob.php` with strict types, tenant header forwarding, error handling, and Stripe Cashier team metered usage reporting (`$team->subscription('default')?->reportUsage($totalTokens)`).

- [ ] **Step 4: Run Pest to verify Green**

Run:
```bash
vendor/bin/pest tests/Feature/A2aProtocolTest.php
```
Expected: PASS (`5 passed`).

- [ ] **Step 5: Format and commit**

Run:
```bash
vendor/bin/pint --dirty --format agent
git add app/Ai/A2a/RemoteAdkAgentTool.php app/Jobs/RunTenantAdkWorkflowJob.php tests/Feature/A2aProtocolTest.php
git commit -m "feat(a2a): add RemoteAdkAgentTool client and metered RunTenantAdkWorkflowJob"
```

### Task 8: Implement Google ADK 2.0 Python A2A Microservice (`adk_service/`) & One-Click Bootstrapper

**Files:**
- Create: `adk_service/requirements.txt`
- Create: `adk_service/agent.py`
- Create: `adk_service/test_agent_a2a.py`
- Create: `setup_electrik_agent_kit.sh`

- [ ] **Step 1: Write the failing Python test verifying the ADK 2.0 A2A service contract**

Create `adk_service/test_agent_a2a.py`:

```python
"""Unit test for the Google ADK 2.0 A2A microservice contract."""
import ast
import pathlib
import unittest

class AdkA2aServiceStructureTest(unittest.TestCase):
    def test_agent_exposes_a2a_endpoints_and_sequential_orchestrator(self) -> None:
        agent_path = pathlib.Path(__file__).parent / "agent.py"
        self.assertTrue(agent_path.is_file(), "adk_service/agent.py must exist")
        source = agent_path.read_text(encoding="utf-8")
        tree = ast.parse(source)
        self.assertIn("/.well-known/agent.json", source)
        self.assertIn("/a2a/tasks/send", source)
        self.assertIn("SequentialAgent", source)
        self.assertIn("electrik_triage_agent", source)
        self.assertIn("electrik_synthesis_agent", source)

if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the Python test to verify failure or baseline**

Run:
```bash
python3 -m unittest adk_service/test_agent_a2a.py
```
Expected: FAIL if `adk_service/agent.py` is missing or incomplete.

- [ ] **Step 3: Implement `adk_service/agent.py`, `adk_service/requirements.txt`, and `setup_electrik_agent_kit.sh`**

Create `adk_service/requirements.txt`:

```text
google-adk>=2.0.0
fastapi>=0.115.0
uvicorn>=0.32.0
```

Create `adk_service/agent.py` (with `triage_agent`, `execution_agent`, `root_agent = SequentialAgent(...)`, `GET /.well-known/agent.json`, and `POST /a2a/tasks/send`) and update `setup_electrik_agent_kit.sh` so a single `bash setup_electrik_agent_kit.sh` command provisions all directories, files, permissions, skills, and A2A components idempotently.

- [ ] **Step 4: Run the full verification suite (Python + Pest 5)**

Run:
```bash
python3 -m unittest adk_service/test_agent_a2a.py
python3 .agents/skills/laravel-migration-validator/scripts/validate_migration.py database/migrations
vendor/bin/pest
vendor/bin/pint --test
```
Expected: All Python unittests, migration validations, Pest 5 feature/unit/architecture tests, and Laravel Pint checks pass with exit code `0`.

- [ ] **Step 5: Commit final milestone and reset Antigravity context**

Run:
```bash
git add adk_service/ setup_electrik_agent_kit.sh
git commit -m "feat(adk): add Google ADK 2.0 SequentialAgent A2A service and one-click setup script"
```
Then execute `/clear` inside [Antigravity CLI](https://antigravity.google/docs/cli/overview/).

## 4. Plan Self-Review & Verification Matrix

1. **Spec Coverage**:
   - **Electrik 5.5+ MIT & Slate 3**: Covered in Tasks 1, 2, 3, and 4 (`AGENTS.md`, `.ai/rules/`, `electrik-tenant-scaffold`, `slate-blade-ui`, `electrik-cashier-billing`).
   - **Antigravity 2.0 & CLI**: Covered in Tasks 2 and 4 (`.gemini/settings.json` with `enableTerminalSandbox: true`, `.agents/mcp_config.json`, `.agents/bin/statusline.sh`, and `/clear` micro-transactions).
   - **Laravel Boost 2.10+ & Laravel AI SDK**: Covered in Tasks 2, 3, 4, and 5 (`laravel-boost` MCP, `.ai/rules/`, `.ai/guidelines/`, `App\Ai\SkillRegistry`, `App\Ai\Agents\TenantCopilotAgent`).
   - **Google ADK 2.0 & Mandatory Bidirectional A2A Adaptation**: Covered in Tasks 6, 7, and 8 (`A2aServerController`, `RemoteAdkAgentTool`, `RunTenantAdkWorkflowJob`, `adk_service/agent.py`, and `A2aProtocolTest`).
2. **Step Scan**: Every task follows the 5-step TDD micro-transaction rhythm (Write Failing Test -> Verify Red -> Implement Minimal Code -> Verify Green -> Pint & Commit).
3. **Type Consistency**: `strict_types=1` is enforced across all PHP classes and tests; `teamId` (`int`), `sessionId` (`string`), and A2A JSON payload schemas (`id`, `status`, `message.role`, `message.parts.0.text`, `metadata.team_id`) match identically across `A2aServerController`, `RemoteAdkAgentTool`, `RunTenantAdkWorkflowJob`, and `adk_service/agent.py`.
4. **Edge Cases Tested**:
   - Missing `X-Electrik-Team-Id` / `metadata.team_id` in A2A requests returns `422 MISSING_TENANT_CONTEXT` instead of leaking cross-tenant state.
   - Invalid `X-A2A-Api-Key` when `services.adk.server_api_key` is set returns `401 INVALID_A2A_API_KEY`.
   - Unregistered skill name in `SkillRegistry::load()` throws `InvalidArgumentException`.
   - Destructive SQL (`DROP`, `truncate`) or missing `down()` in migrations fails `validate_migration.py` before `php artisan migrate` can run.
