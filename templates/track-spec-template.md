# Track Spec Template

Frozen when track completes. Per-track file.

```yaml
# Spec: {Track ID} — {Track Name}
status: draft|approved|in-progress|complete|superseded
created: {date}
approved: {date}

summary: {one paragraph — what this delivers and why}

user_story:
  as: {user type}
  want: {action}
  so_that: {benefit}

acceptance:
  S1: {criterion — specific, testable}
  S2: {criterion}
  S3: {criterion}

non_goals:
  - {explicitly excluded}

approach:
  overview: {high-level how}
  decisions:
    - choice: {what}
      over: {alternatives}
      why: {rationale}
  depends: [{prerequisites}]

ux_notes: {considerations}
deferred: [{future track items}]
open_questions:                    # resolve before approval
  - {question}

# Clause IDs: SPEC.S1, S2, etc. Frozen on completion.
```

## Lifecycle
draft → approved → in-progress → complete → superseded
