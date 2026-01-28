# Naming Conventions

Consistent naming across all pipeline artifacts.

## Track IDs

Format: `T{number}-{slug}`

Examples:
- `T01-auth-system`
- `T02-receipt-upload`
- `T03-reporting-dashboard`

Rules:
- Sequential numbers, zero-padded to 2 digits
- Slug: lowercase, hyphens only, max 30 chars
- Descriptive of the feature/fix

## Task IDs

Format: `{track-id}.{number}`

Examples:
- `T01-auth-system.01`
- `T01-auth-system.02`
- `T02-receipt-upload.01`

Rules:
- Sequential within track
- Referenced in commits and logs

## Pivot Slugs

Format: `{YYYY-MM-DD}-{slug}`

Examples:
- `2026-01-28-switch-to-postgres`
- `2026-02-15-drop-mobile-support`

Rules:
- Date of decision
- Slug describes the change

## Clause IDs

Format: `{DOC}.{letter}{number}`

Examples:
- `VISION.V1` - First vision clause
- `WORKFLOW.W3` - Third workflow rule
- `PATTERNS.P2` - Second pattern
- `SPEC.S1` - First spec acceptance criterion

Rules:
- DOC: VISION, WORKFLOW, PATTERNS, PITFALLS, RISKS, SPEC
- Letter: First letter of doc type
- Number: Sequential within doc

## Date Formats

| Context | Format | Example |
|---------|--------|---------|
| Filenames | `YYYY-MM-DD` | `2026-01-28` |
| Timestamps | ISO 8601 | `2026-01-28T04:15:00Z` |
| Display | Human readable | `Jan 28, 2026` |

## Branch Names

Format: `{type}/{track-id}`

Examples:
- `feat/T01-auth-system`
- `fix/T05-login-bug`
- `refactor/T03-cleanup`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
