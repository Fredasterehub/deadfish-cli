# Patterns Template

Living document. Budget: 400 tokens. Tiers: 🧪 experimental (1 use) → ✅ blessed (2+) → 🌅 sunset.

```yaml
# PATTERNS.md
# Last updated: {date}

patterns:
  - id: P1
    name: {name}
    tier: blessed          # experimental | blessed | sunset
    added: {date}
    uses: {count}
    what: {description}
    when: {trigger conditions}
    example: |
      {code snippet}
    why: {rationale}
    revisit_when: {condition}

  - id: P2
    name: {name}
    tier: experimental
    added: {date}
    uses: 1
    track: {first-use track}
    what: {description}
    notes: {observations}

sunset:
  - id: PS1
    name: {name}
    date: {date}
    replaced_by: P{n}
    reason: {why}

# Clause IDs: PATTERNS.P1, P2, etc. Experimental: PE prefix until blessed.
```

## Promotion Rules
- experimental → blessed: 2+ successful uses, no issues
- blessed → sunset: better alternative found or consistent friction
- Checker: REJECT blessed violations, WARN sunset, NOTE experimental
