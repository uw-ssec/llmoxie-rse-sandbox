---
agent: agent
description: 'Capture environment, data, seeds, and config so a result can be reproduced'
tools: ['read', 'execute/runInTerminal', 'search/codebase', 'search', 'edit/editFiles']
---

Use the `ensuring-reproducibility` skill to handle this request.

Target result / experiment to make reproducible: ${input:topic:which result, e.g. "the warming-trend estimate from the samples/ocean analysis"}

If nothing was provided, ask which result or experiment to make reproducible.
