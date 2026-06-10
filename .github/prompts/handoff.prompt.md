---
agent: agent
description: 'Create a handoff document to transfer work context to another session'
tools: ['read', 'search/codebase', 'search', 'execute/runInTerminal', 'edit/editFiles']
---

Use the `creating-handoffs` skill to handle this request.

Optional focus note: ${input:note:anything to emphasize in the handoff (blank = summarize the whole session)}

If no focus note was provided, summarize the whole session in the handoff.
