---
marp: true
theme: sandbox
paginate: true
title: "Package a Climate Model with the Research Loop"
description: "LLMoxie NAIRR Sandbox — ai-research-workflows guided demo"
---

<!-- _class: lead -->

# Package a Climate Model with the Research Loop

## A guided demo of the RSE Agent research workflows

*Drive Copilot Chat through four phases — watch auditable artifacts appear in `docs/rse/specs/`.*

---

## Why workflows, not one-shot prompts

AI assistants write code well, but used ad hoc they skip the rigor research needs: they edit before understanding, lose the *why* when a chat ends, and rarely prove a result holds.

A **workflow** is a named, reusable prompt that runs one phase and writes a durable, cross-linked artifact to `docs/rse/specs/`.

- **Research software engineers** get planning, testing, and review rigor.
- **Researchers** get a reproducible record of *what was decided and why* — one that survives the session.

> Context becomes a file in your repo, not a chat log.

---

## The research loop at a glance

| Phase | Slash command | Writes |
|---|---|---|
| 1. Research | `/research` | `docs/rse/specs/research-<slug>.md` |
| 2. Plan | `/plan` | `docs/rse/specs/plan-<slug>.md` |
| 3. Implement | `/implement` | `docs/rse/specs/implement-<slug>.md` (+ updates the plan) |
| 4. Validate | `/validate` | `docs/rse/specs/validation-<slug>.md` |
| any time | `/handoff` | `docs/rse/specs/handoff-<ts>-<slug>.md` |

We run **four phases** here. The plugin ships more (`/iterate-plan`, `/experiment`, `/reproduce`, `/harden`).

Each command is a Copilot Chat **prompt file** that hands off to a reusable **skill** — installed for you by the devcontainer.

---

## Before you start

- A **UW SSEC model** is selected in Copilot Chat (see the **Get Started** panel — Help → Get Started).
- This deck is open in **Marp preview** — `research-loop.md` → "Open Preview to the Side".
- The **Copilot Chat** panel is open beside the preview (`Ctrl+Shift+I`).

You'll read a slide, type its prompt in Chat, then open the artifact it writes.

---

## Commit first — git is your safety net

Before the agent touches anything, start from a clean tree:

```bash
git status        # should be clean
git add -A && git commit -m "checkpoint before research loop"   # if not
```

Now `git diff` shows **exactly** what the agent changed, and `git restore .` is a one-command undo.

> The artifacts in `docs/rse/specs/` are the *plan* trail. git is the *code* trail. Together they keep you in control.

---

## The scenario: package the climate scripts

Under `samples/` you have loose scripts — no package, no tests:

- `climate_model.py` — the model
- `climate_data_analysis.py` — analysis over `climate_data.csv`
- `model_visualization.py` — plots

**Goal:** turn them into an installable Python package, following Scientific Python guidelines.

We'll run `/research → /plan → /implement → /validate` and watch `docs/rse/specs/` fill in.

---

## Phase 1 — `/research`

In Copilot Chat, type:

```text
/research how the scripts under samples/ are structured and what's missing for them to be an installable package
```

**You'll see:** a written summary of the current code, entry points, and gaps.

**Then open:** `docs/rse/specs/research-*.md` — the durable research note.

> Read it. This is the context every later phase builds on.

---

## Phase 2 — `/plan`

```text
/plan package the samples/ climate scripts as an installable package following Scientific Python guidelines
```

**You'll see:** a phased plan with components, dependencies, and **success criteria** (Automated + Manual).

**Then open:** `docs/rse/specs/plan-*.md` — and read the success criteria. That's the contract `/validate` checks later.

> Plan too broad? Tighten the scope now — a tight plan means a reviewable diff.

---

## Phase 3 — `/implement`

```text
/implement docs/rse/specs/plan-<slug>.md
```

(Use the real filename from Phase 2.)

**You'll see:** the agent works **phase by phase**, running checks and pausing for your verification.

**Commit after each green phase:**

```bash
git add -A && git commit -m "implement: phase N"
```

This is the slow one — while it runs, read the next two slides.

---

## While `/implement` runs: what to watch for

| Failure | Looks like | Mitigation |
|---|---|---|
| Context exhaustion | Forgets earlier instructions | `/handoff`, then a fresh chat; smaller scope |
| Looping | Same tool over and over | Interrupt; restate the goal |
| Confident wrong answer | "Done!" when nothing changed | Always `/validate`; trust nothing without proof |
| Scope creep | Edits files you didn't mention | Tight `/plan`; narrow per-phase scope |

> The agent is an eager coworker. Coworkers get pushback.

---

## Review the diff, not the chat

The agent's "Done!" is a **claim**. `git diff` is the **evidence**.

```bash
git diff            # what actually changed this phase
git restore .       # undo if it went wrong
```

- Read it like a colleague's pull request.
- Commit per phase, so a bad later phase rolls back cleanly.
- Small per-phase scope → small diff → you'll actually read it.

---

## Phase 4 — `/validate`

```text
/validate docs/rse/specs/plan-<slug>.md
```

**You'll see:** each success criterion checked, with pass/fail and evidence (commands run, files compared).

**Then open:** `docs/rse/specs/validation-*.md`.

> `/validate` is a quality gate, not a vibe check. If it fails, you caught it — not your collaborator.

---

## What you've got now

Four phases later, `docs/rse/specs/` holds a **cross-linked decision record**:

```text
research-<slug>.md   ← the understanding
plan-<slug>.md       → cites the research
implement-<slug>.md  → cites the plan
validation-<slug>.md → cites the plan's criteria
```

Committed alongside the code, this survives the session and transfers to the next person — no information lost.

> That's the difference from a chat log: durable, reviewable, reproducible context.

---

## Now point it at your own code

- Swap the climate scenario for **your** repository — the loop is the same.
- Use `/handoff` to carry full context into a fresh chat when one gets long.
- Put your conventions, data shapes, and "don't touch X" in **`AGENTS.md`** (or `.github/copilot-instructions.md`) — that's where your research context lives.

> Same workflow, your science. Pick the loop length to match the half-life of the code.
