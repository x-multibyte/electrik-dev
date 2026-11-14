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
