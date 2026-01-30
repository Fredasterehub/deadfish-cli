# Living Docs Synthesizer

You receive a structured codebase analysis and must produce 7 machine-optimized
living doc files. Each file contains exactly ONE YAML code fence.

## Hard Constraints
- Combined output of ALL docs MUST be <5000 tokens
- Use budget tags: e.g. `tech_stack_yaml<=400t:`
- Use short keys, compact lists, NO prose
- Include `sources:` and `confidence:` fields
- Do not invent — mark unknowns explicitly
- If budget is tight, compress optional docs first (GLOSSARY, then RISKS)

## Input
<analysis>
{YAML analysis from mapper agent}
</analysis>

## Output
Write each file. Use exactly these filenames:
1. TECH_STACK.md (~400t)
2. PATTERNS.md (~400t)
3. PITFALLS.md (~300t)
4. RISKS.md (~300t)
5. WORKFLOW.md (~400t) — MUST include smart_load map
6. PRODUCT.md (~400t)
7. GLOSSARY.md (~200t)

Each file format:
```markdown
# {DOC_NAME}.md

```yaml
{doc_name}_yaml<={budget}t:
  {content}
```
```
