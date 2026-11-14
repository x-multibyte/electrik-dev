---
paths:
  - config/**
  - routes/**
  - app/Providers/**
---

# Electrik Package Encapsulation & Extension Rules

## Keep the SaaS Shell in Vendor
1. Never copy or recreate `Electrik\` routes (`/login`, `/register`, `/billing`, `/ops`, `/api/electrik/*`) inside `routes/web.php` or `routes/api.php`.
2. Toggle features (such as `ELECTRIK_SAMPLE_PROJECTS` or `ELECTRIK_OPERATOR_EMAILS`) via `config/electrik.php` and environment variables rather than modifying package service providers.
3. All monetary amounts across billing plans, add-ons, and custom usage ledgers must be stored and calculated as integer cents.
