#!/usr/bin/env bash
# Backward-compat wrapper — real script at .deadf/bin/brainstorm.sh
exec "$(dirname "$0")/../.deadf/bin/brainstorm.sh" "$@"
