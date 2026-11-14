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
