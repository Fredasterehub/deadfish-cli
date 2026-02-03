# Output Contract (auto-loaded)

Final line token rule
- The last line of orchestrator output must be exactly one of: `CYCLE_OK` | `CYCLE_FAIL` | `DONE`.
- Optional task summary lines may appear before the final token only.

Sentinel block-only rules
- When a template specifies a sentinel block, output must be block-only (no prose, no code fences).
- Exactly one opener and one closer; nonce must match the cycle nonce.
- No blank lines or tabs inside blocks; fixed field order where specified.

CYCLE_OK / CYCLE_FAIL conditions
- `CYCLE_OK`: action completed successfully and state recorded.
- `CYCLE_FAIL`: action failed, invalid state, lock failure, or deterministic verifier failure.
- `DONE`: phase is `complete` after summarize.
