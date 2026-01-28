# Task Template

Copy and fill for new tasks.

```xml
<task id="">
  <name></name>
  
  <context>
    <track></track>
    <spec_ref></spec_ref>
    <plan_ref></plan_ref>
  </context>
  
  <files>
    <file action="create"></file>
  </files>
  
  <action>
  </action>
  
  <source_refs>
    <!-- Remove if not using existing data -->
    <ref type=""></ref>
  </source_refs>
  
  <assumptions>
    <assumption></assumption>
  </assumptions>
  
  <non_goals>
    <non_goal></non_goal>
  </non_goals>
  
  <verify>
    <step>
      <command></command>
      <expected></expected>
    </step>
  </verify>
  
  <done>
    <criterion contract=""></criterion>
  </done>
  
  <rollback>
    <step></step>
  </rollback>
</task>
```
