---
paths:
  - resources/views/**
  - app/Livewire/**
---

# Electrik Slate 3 UI & Livewire 4 Rules

## Exclusive `<x-slate::*>` Component Usage
1. Build all UI views using anonymous Blade components from Electrik Slate 3 (`<x-slate::button>`, `<x-slate::card>`, `<x-slate::input>`, `<x-slate::dialog>`, `<x-slate::table>`, etc.) and `<x-slate-block::*>` for marketing sections.
2. Consult `https://slate.electrik.dev/llms-full.txt` or the `electrik-slate` MCP server before composing new forms, dialogs, or data tables.
3. Use Slate semantic CSS tokens (`--slate-primary`, `--slate-background`, `--slate-foreground`, `--slate-muted`) with Tailwind CSS v4 so built-in dark mode works automatically.
4. Bind forms with Livewire 4 `wire:model` and pass validation state natively through Slate form primitives; support RTL layouts (`ar`) and localized strings (`__()`) across all 5 supported locales (`en`, `es`, `fr`, `ar`, `hi`).
