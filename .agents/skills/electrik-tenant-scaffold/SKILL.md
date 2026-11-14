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
