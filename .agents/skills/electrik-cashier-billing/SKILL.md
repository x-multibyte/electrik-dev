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
