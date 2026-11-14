# Project Rules Index

- `electrik-package-boundary.md` — Applies to `config/**`, `routes/**`, `app/Providers/**`: Enforces vendor isolation for `Electrik\` and configuration-driven customization.
- `team-tenancy-models.md` — Applies to `app/Models/**`, `database/migrations/**`: Enforces `BelongsToTeam` multi-tenancy, PHP 8.4 model conventions, and integer-cents currency storage.
- `slate-livewire-views.md` — Applies to `resources/views/**`, `app/Livewire/**`: Enforces Electrik Slate 3 `<x-slate::*>` anonymous components, Tailwind CSS v4 tokens, and Livewire 4 patterns.
- `controllers-and-requests.md` — Applies to `app/Http/**`: Enforces thin controllers, FormRequest validation, and team-scoped Spatie policy authorization.
