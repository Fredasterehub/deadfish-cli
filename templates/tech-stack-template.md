# Tech Stack Template

Living document. Updated when stack decisions change.

---

```markdown
# Tech Stack: {project-name}

*Last updated: {ISO date}*

## Core Stack

### Language & Runtime
| Choice | Version | Rationale | Revisit When |
|--------|---------|-----------|--------------|
| {Language} | {version} | {why chosen} | {trigger for reconsideration} |

### Framework
| Choice | Version | Rationale | Revisit When |
|--------|---------|-----------|--------------|
| {Framework} | {version} | {why chosen} | {trigger} |

### Database
| Choice | Version | Rationale | Revisit When |
|--------|---------|-----------|--------------|
| {Database} | {version} | {why chosen} | {trigger} |

## Key Libraries

| Library | Purpose | Version | Locked? |
|---------|---------|---------|---------|
| {lib1} | {purpose} | {ver} | Yes/No |
| {lib2} | {purpose} | {ver} | Yes/No |

## Infrastructure

| Component | Choice | Notes |
|-----------|--------|-------|
| Hosting | {choice} | {notes} |
| CI/CD | {choice} | {notes} |
| Monitoring | {choice} | {notes} |

## Constraints

### Hard Constraints (from VISION)
- {Constraint 1 - e.g., "Must self-host"}
- {Constraint 2}

### Soft Constraints (preferences)
- {Preference 1 - e.g., "Prefer TypeScript"}
- {Preference 2}

## Decisions Log

| Date | Decision | Alternatives Considered | Why |
|------|----------|------------------------|-----|
| {date} | {what we decided} | {other options} | {rationale} |

## Dependency Policy

### Security Updates
- Critical: Apply within 24h, bypass normal review
- High: Apply within 1 week
- Medium/Low: Batch in maintenance tracks

### Major Upgrades
- Require dedicated track
- Test in isolation first
- Document breaking changes

---
*Living document. Update when stack decisions change.*
*Clause IDs: Reference as TECH.T1, TECH.T2, etc. for constraints.*
```

## Update Triggers

Update TECH_STACK.md when:
- Adding new dependency
- Upgrading major versions
- Discovering friction with current choice
- Security considerations change
- "Revisit when" condition is met
