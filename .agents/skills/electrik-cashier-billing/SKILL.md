---
name: electrik-cashier-billing
description: Implement or modify team-level Stripe subscriptions, plan feature gates, add-ons, and metered usage billing in Electrik using Laravel Cashier.
---

# Electrik Cashier Team Billing

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
- Report metered consumption via queued jobs or team billing helpers after successful execution:
  ```php
  if (method_exists($team, 'reportMeterEvent')) {
      $team->reportMeterEvent('ai_workflow_runs', quantity: 1);
  }
  ```
- Always include fallback logging/no-op handling when teams run in local sandbox or free-tier mode without an active Stripe customer.
