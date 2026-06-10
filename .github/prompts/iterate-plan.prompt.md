---
agent: agent
description: 'Update an existing implementation plan based on feedback'
tools: ['read', 'search/codebase', 'search', 'search/usages', 'edit/editFiles']
---

Use the `iterating-plans` skill to handle this request.

Plan to update and the feedback to apply: ${input:plan:plan path and feedback, e.g. "docs/rse/specs/plan-climate-package.md — split phase 2 into smaller steps"}

If nothing was provided, ask which plan to update and what feedback to apply before proceeding.
