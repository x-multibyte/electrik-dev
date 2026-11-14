---
name: slate-blade-ui
description: Build and refactor Blade views and Livewire 4 components using Electrik Slate 3 anonymous components (<x-slate::*>) and Tailwind CSS v4 tokens.
---

# Electrik Slate 3 & Livewire 4 UI

Build all application and marketing UI using Electrik Slate 3 anonymous Blade components (`<x-slate::*>`, `<x-slate-block::*>`) and Livewire 4.

## 1. Component & Layout Rules
- Query installed components and schema via the `electrik-slate` MCP tools (`list_components`, `get_component_docs`, `list_blocks`) or consult `https://slate.electrik.dev/llms.txt`.
- Use `<x-slate::card>`, `<x-slate::button>`, `<x-slate::input>`, `<x-slate::modal>`, `<x-slate::table>`, and `<x-slate-block::*>` sections instead of raw unstyled HTML controls.
- NEVER install or introduce React, Vue, Inertia, Flux UI, or shadcn/ui.

## 2. Styling & Design Tokens
- Use Tailwind CSS v4 `@theme` design tokens (`--slate-primary`, `--slate-background`, `--slate-foreground`, `--slate-surface`, `--slate-border`) and paired light/dark utility classes.
- Preserve existing `Electrik\` shell layouts by customizing `config/electrik.php` and published slots rather than copying vendor views into `resources/views/vendor` unless explicitly required.

## 3. Livewire 4 Integration
- Keep interactive UI state in Livewire 4 components paired with Form Objects or FormRequests.
- Validate team ownership (`$this->authorize(...)`) in every Livewire action that mutates tenant records.
