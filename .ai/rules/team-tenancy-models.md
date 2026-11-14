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
