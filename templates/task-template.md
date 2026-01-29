# Task Template

Copy and fill. All fields required unless noted optional.

```xml
<task id="{track-id}.{number}">
  <name>{brief name}</name>
  <context>
    <track>{track-id}</track>
    <spec_ref>{path}</spec_ref>
    <plan_ref>{path}</plan_ref>
  </context>
  <files>
    <file action="create|modify|delete">{path}</file>
  </files>
  <action>{specific implementation instructions}</action>
  <source_refs><!-- optional: only if using existing data -->
    <ref type="url|file|doc">{reference}</ref>
  </source_refs>
  <assumptions><!-- optional -->
    <assumption>{assumption}</assumption>
  </assumptions>
  <non_goals><!-- optional -->
    <non_goal>{exclusion}</non_goal>
  </non_goals>
  <verify>
    <step>
      <command>{executable command}</command>
      <expected>{expected result}</expected>
    </step>
  </verify>
  <done>
    <criterion contract="{clause-id}">{pass/fail criterion}</criterion>
  </done>
  <rollback>
    <step>{undo instruction}</step>
  </rollback>
</task>
```
