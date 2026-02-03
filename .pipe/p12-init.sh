#!/usr/bin/env bash
# Backward-compat wrapper — real script at .deadf/bin/init.sh
exec "$(dirname "$0")/../.deadf/bin/init.sh" "$@"
