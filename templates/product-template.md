# Product Template

Living document. Budget: 400 tokens.

```yaml
# PRODUCT.md
# Last updated: {date}
# Updated by: {model/person}
# Reason: {what changed}

goals:
  primary: {one sentence}
  secondary: [{goal2}, {goal3}]

users:
  primary:
    who: {description}
    context: {when/where}
    jtbd: [{job1}, {job2}]
  secondary:
    - {type}: {brief}

metrics:
  - name: {metric}
    current: {value}
    target: {value}
    status: green|yellow|red

ux_constraints:
  - {constraint}

understanding:
  known: [{validated1}, {validated2}]
  testing: [{hypothesis1}]
  changed:
    - date: {date}
      what: {change and why}

# Living doc. Update after tracks when understanding improves.
```
