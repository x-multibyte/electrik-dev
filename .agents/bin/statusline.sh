#!/usr/bin/env bash
payload="$(cat)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"
printf "\033[1;36m[Electrik SaaS]\033[0m \033[1;32m⎇ %s\033[0m | Sandbox: ON | A2A: Enabled\n" "$branch"
