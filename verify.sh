#!/usr/bin/env bash
# Backward-compat wrapper — real script moved to .deadf/bin/
exec "$(dirname "$0")/.deadf/bin/verify.sh" "$@"
