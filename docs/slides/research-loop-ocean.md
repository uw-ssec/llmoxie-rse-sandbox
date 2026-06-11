---
marp: true
theme: sandbox
paginate: true
title: "Test a Warming Hypothesis with the Research Loop"
description: "LLMoxie NAIRR Sandbox — ai-research-workflows oceanographic research arc"
---

<!-- _class: lead -->

# Test a Warming Hypothesis with the Research Loop

## A hypothesis-driven research arc with the RSE Agent workflows

*Drive Copilot Chat from hypothesis to reproducible result — watch auditable artifacts appear in `docs/rse/specs/`.*

---

## Why a hypothesis needs a workflow

A result without a record of how you got it is a **claim**. Run ad hoc, an AI assistant will happily produce a number — and lose the *why*, the methods it rejected, and whether the result even holds.

A **workflow** is a named, reusable skill that runs one phase and writes a durable, cross-linked artifact to `docs/rse/specs/`.

- **Researchers** get a reproducible decision record: hypothesis, methods compared, result, provenance.
- **Research software engineers** get experiment and validation rigor baked into the loop.

> This is the **science** companion to the packaging deck (`research-loop.md`): same loop, told as a research arc.

---

## The research arc at a glance

| Phase | Slash command | Writes |
|---|---|---|
| 1. Research the methods | `/researching` | `docs/rse/specs/research-<slug>.md` |
| 2. Plan the analysis | `/planning-implementations` | `docs/rse/specs/plan-<slug>.md` |
| 3. Test the methods | `/running-experiments` | `docs/rse/specs/experiment-<slug>.md` |
| 4. Implement | `/implementing-plans` | `docs/rse/specs/implement-<slug>.md` (+ updates the plan) |
| 5. Get results | `/validating-implementations` | `docs/rse/specs/validation-<slug>.md` |
| 6. Make it reproducible | `/ensuring-reproducibility` | a `## Reproducibility` section in `experiment-`/`implement-<slug>.md` |

`/hardening-research-code` (regression + correctness tests) is the natural next step — we name it at the end.

Each command is a reusable **Agent Skill** from the RSE Agent Plugins — discovered by Copilot Chat straight from this repository.

---

## Before you start

- A **UW SSEC model** is selected in Copilot Chat (see the sandbox walkthrough — Help → Welcome).
- This deck is open in **Marp preview** — `research-loop-ocean.md` → "Open Preview to the Side".
- The **Copilot Chat** panel is open beside the preview (`Ctrl+Shift+I`).

You'll read a slide, type its prompt in Chat, then open the artifact it writes.

---

## Commit first — git is your safety net

Before the agent touches anything, start from a clean tree:

```bash
git status        # should be clean
git add -A && git commit -m "checkpoint before research arc"   # if not
```

Now `git diff` shows **exactly** what the agent changed, and `git restore .` is a one-command undo.

> The artifacts in `docs/rse/specs/` are the *reasoning* trail. git is the *code* trail. Together they keep you in control.

---

## The scenario: is the ocean warming here?

Under `samples/ocean/` you have one buoy's daily sea-surface temperature:

- `buoy_sst.csv` — ~10 years of daily `sst_c`
- `README.md` — documents the data's **ground truth** so you can check the loop's answer
- `generate_buoy_sst.py` — the seeded generator that produced it
- `test_generate_buoy_sst.py` — a regression test pinning the generator to that truth

**Hypothesis:** this buoy's SST has a warming trend *beyond* its seasonal cycle.
**Goal:** is the warming real, and how big? We'll run the loop and check the answer against the documented truth (≈ 0.03 °C/yr).

> The data is **synthetic** with a documented structure, so the answer is checkable here. On your own real data the outcome is genuinely uncertain — that's when the experiment earns its keep.

---

## Phase 1 — `/researching`

In Copilot Chat, type:

```text
/researching I'd like to figure out methods to separate a long-term trend from a seasonal cycle in a daily temperature time series, for samples/ocean/buoy_sst.csv
```

**You'll see:** a survey of approaches — decomposition methods (harmonic regression, STL, moving-average deseasonalization) plus a robust slope estimator (Theil–Sen) to apply to the deseasonalized residuals — with trade-offs.

**Then open:** `docs/rse/specs/research-*.md` — the durable methods note every later phase builds on.

> This is the "research the methods" step — prior art before code.

---

## Phase 2 — `/planning-implementations`

```text
/planning-implementations an analysis that estimates the warming trend in samples/ocean/buoy_sst.csv after removing the seasonal cycle, with success criteria
```

**You'll see:** a phased plan with components, dependencies, and **success criteria** (Automated + Manual) — e.g. *recovers the trend within a confidence interval*.

**Then open:** `docs/rse/specs/plan-*.md` — and read the success criteria. That's the contract `/validating-implementations` checks later.

> Tighten the scope now — a tight plan means a reviewable result.

---

## Phase 3 — `/running-experiments` (the centerpiece)

```text
/running-experiments compare harmonic regression vs STL decomposition for recovering the warming trend in samples/ocean/buoy_sst.csv
```

**You'll see:** the agent **builds and runs each approach for real**, measures how well each recovers the trend, and recommends one with evidence.

**Then open:** `docs/rse/specs/experiment-*.md` — the head-to-head comparison.

> This is where a research claim is earned, not asserted. It's the slow phase — while it runs, read the next two slides.

---

## The experiment Iron Law

**An experiment is real measured code, or it is not an experiment.**

Every approach in the comparison must be actually built and run. A comparison with one side *assumed* —

> "harmonic regression is obviously better, so I didn't run STL"

— is an opinion with a number stapled to one half. For a research result, that is the difference between a finding and a guess. If an approach genuinely can't be built, the skill labels it an *unverified assumption* — never a benchmark.

---

## Review the diff and the evidence, not the chat

The agent's "Done!" is a **claim**. `git diff` and the artifact are the **evidence**.

```bash
git diff            # what actually changed
git restore .       # undo if it went wrong
```

- Read the experiment and validation artifacts like a colleague's pull request.
- Commit per phase, so a bad later phase rolls back cleanly.
- Small per-phase scope → small diff → you'll actually read it.

---

## Phase 4 — `/implementing-plans`

```text
/implementing-plans docs/rse/specs/plan-<slug>.md
```

(Use the real filename from Phase 2.)

**You'll see:** the agent implements the recommended method **phase by phase**, running checks and pausing for your verification.

**Commit after each green phase:**

```bash
git add -A && git commit -m "implement: phase N"
```

---

## Phase 5 — `/validating-implementations`

```text
/validating-implementations docs/rse/specs/plan-<slug>.md
```

**You'll see:** each success criterion checked, with pass/fail and evidence. The recovered warming slope should land near the documented truth.

**Then open:** `docs/rse/specs/validation-*.md`, then check it against `samples/ocean/README.md` (≈ 0.03 °C/yr).

> `/validating-implementations` is a quality gate, not a vibe check. The known answer is what makes it honest.

---

## Phase 6 — `/ensuring-reproducibility`

```text
/ensuring-reproducibility the warming-trend estimate from the samples/ocean experiment
```

**You'll see:** a provenance record — interpreter + `pixi.lock`, code commit, the data's seed and content hash, config, exact commands — captured **and then re-run in a clean environment** to confirm the result holds.

**Where it lands:** the skill **appends a `## Reproducibility` section to the artifact that already holds the result** — `experiment-<slug>.md` (or `implement-<slug>.md`) — not a separate file. It only creates `reproducibility-<slug>.md` when there's no existing artifact to append to.

> A record isn't reproducible until it's been reproduced. Capturing env, seed, and commands is necessary; re-running them in a clean room is what turns the claim into a finding.

---

## What you've got now

Six phases later, `docs/rse/specs/` holds a **cross-linked research record**:

```text
research-<slug>.md     ← the methods
plan-<slug>.md         → cites the research
experiment-<slug>.md   → tests the methods (+ ## Reproducibility: env, seed, data, commands)
implement-<slug>.md    → cites the plan
validation-<slug>.md   → cites the plan's criteria
```

Committed alongside the code, this survives the session and transfers to the next person — hypothesis, evidence, and provenance intact.

> That's the difference from a chat log: a durable, reviewable, reproducible record.

---

## Now test your own hypothesis

- Swap the buoy scenario for **your** data and question — the arc is the same.
- Use **`/creating-handoffs`** to carry full context into a fresh chat when a session gets long.
- When the result must be trustworthy, run **`/hardening-research-code`**: regression and correctness tests against a known reference. Here, `test_generate_buoy_sst.py` already pins the *data*; `/hardening-research-code` adds the same protection to your *analysis*.
- Put your conventions, data shapes, and "don't touch X" in **`AGENTS.md`** (or `.github/copilot-instructions.md`) — that's where your research context lives.

> Same loop, your science. From hypothesis to a result you can defend.
