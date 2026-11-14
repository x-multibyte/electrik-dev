---
paths:
  - app/Http/**
---

# Controllers, Validation, and Authorization Rules

## Thin Controllers & Team-Scoped Policies
1. Controllers in `app/Http/Controllers/` may only perform Policy/Gate authorization, FormRequest validation, and Eloquent model or Queued Job dispatch.
2. Never write raw SQL queries, external HTTP calls, or multi-step business orchestration inside controllers; dispatch queued jobs (`ShouldQueue`) for slow external APIs or AI agent invocations.
3. Always verify Spatie team-scoped permissions (`$user->can(...)` within current team context) and Policy ownership before mutating any `BelongsToTeam` model.
