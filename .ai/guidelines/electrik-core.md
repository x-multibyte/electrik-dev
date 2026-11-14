## Electrik SaaS Starter Kit & Slate 3 Guidelines

This application uses `electrik/electrik` (v5.5+ MIT) as its vendor-encapsulated SaaS shell and `electrik/slate` (v3.0+) for anonymous Blade UI primitives.

### Core Conventions
- **Team-Centric Multi-Tenancy**: Always use `php artisan electrik:make:model` so models include `BelongsToTeam`.
- **Team-Scoped Cashier Billing**: Subscriptions and metered usage belong to `Team`, not `User`.
- **Anonymous Slate Components**: Render UI with `<x-slate::*>` and `<x-slate-block::*>`. Do not install React, Vue, Inertia, or Flux UI.
- **A2A Protocol**: Inter-agent communication follows the A2A spec via `app/Ai/A2a/` and `adk_service/`.
