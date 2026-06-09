---
agent: agent
description: 'Research the codebase and/or external prior art to build context for a task'
tools: ['read', 'search/codebase', 'search', 'search/usages', 'edit/editFiles']
---

Use the `researching` skill to handle this request.

Topic to research (or file references / instructions): ${input:topic:what to research, e.g. "how the scripts under samples/ are structured and what's missing for them to be a package"}

If nothing was provided, enter the skill's Collaborative mode and ask what is needed before proceeding.
