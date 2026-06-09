---
agent: agent
description: 'Validate that an implementation was correctly executed against its plan'
tools: ['read', 'search/codebase', 'search', 'execute/runInTerminal', 'edit/editFiles']
---

Use the `validating-implementations` skill to handle this request.

Plan to validate against: ${input:plan:path to the plan, e.g. docs/rse/specs/plan-climate-package.md}

If nothing was provided, enter the skill's Collaborative mode and ask what is needed before proceeding.
