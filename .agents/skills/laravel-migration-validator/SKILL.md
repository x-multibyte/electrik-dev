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
