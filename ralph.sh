#!/bin/bash
# ralph.sh - Thin wrapper for kick.sh
exec "$(dirname "$0")/.deadf/bin/kick.sh" "$@"
