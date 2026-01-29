# Tech Stack Template

Machine-optimized. Budget: 400 tokens.

```yaml
# TECH_STACK.md
# Last updated: {date}

runtime: {lang}@{version}
framework: {name}@{version}
db: {engine}@{version}/{orm}
cache: {engine}@{version}        # optional
auth: {method}
test: {runner}
build: {tool}
pm: {package-manager}

files:
  entry: {path}
  routes: {path}
  models: {path}
  config: {path}

external:                         # optional
  {service}: {provider}

commands:
  dev: {command}
  build: {command}
  test: {command}
  lint: {command}
  migrate: {command}              # optional

env:
  required: [{VAR1}, {VAR2}]
  optional: [{VAR3}, {VAR4}]
  config: {file}                  # e.g. .env.example

ci:
  runner: {platform}
  deploy: {method}

constraints:
  hard:                           # from VISION
    - {constraint}
  soft:                           # preferences
    - {preference}

# Clause IDs: TECH.T1, TECH.T2, etc.
```

## Update Triggers

- New dependency added
- Major version upgrade
- "Revisit when" condition met
- Stack friction discovered
