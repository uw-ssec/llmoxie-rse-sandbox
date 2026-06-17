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

---

## The research arc at a glance

1. Research the methods
2. Plan the analysis
3. Experiment
4. Implement
5. Validate
6. Ensure Reproducibility

Each step is a reusable **Agent Skill** from the RSE Agent Plugins,
discovered by Copilot Chat straight from this repository.

---

## Before you start

- A **UW SSEC model** is selected in Copilot Chat (see the sandbox walkthrough — Help → Welcome).
- This deck is open in **Marp preview** — `research-loop-ocean.md` → "Open Preview to the Side".
- The **Copilot Chat** panel is open beside the preview (`Ctrl+Shift+I`).

You'll read a slide, type its prompt in Chat, then open the artifact it writes.

> The artifacts in `docs/rse/specs/` are the *reasoning* trail. git is the *code* trail. Together they keep you in control.

---

## The scenario: is the ocean warming here?

Under `samples/ocean/` you have one buoy's daily sea-surface temperature:

- `buoy_sst.csv` — ~10 years of daily `sst_c`
- `GROUND_TRUTH.md` — the data's **ground truth**, for humans only (the agent is told not to read it), so you can check the loop's answer
- `generate_buoy_sst.py` — the seeded generator that produced it
- `test_generate_buoy_sst.py` — a regression test pinning the generator to that truth

**Hypothesis:** this buoy's SST has a warming trend *beyond* its seasonal cycle.
**Goal:** is the warming real, and how big? We'll run the loop and check the answer against the documented truth (≈ 0.03 °C/yr).

> The data is **synthetic** with a documented structure, so the answer is checkable here. On your own real data the outcome is genuinely uncertain — that's when the experiment earns its keep.

---

## Phase 1 — Research

In Copilot Chat, type:

```text
/researching I'd like to figure out methods to separate a long-term trend from a seasonal cycle in a daily temperature time series, for samples/ocean/buoy_sst.csv
```

**This skill is collaborative — it scopes before it searches.** Answer its questions:

- *Codebase, prior art, or both?* → **both**
- *Depth?* → **Moderate**

It then proposes a short research plan to OK, investigates, and presents the findings **before** writing — closing with *"review it and tell me if anything is off."*

**Writes:** `docs/rse/specs/research-<slug>.md` — the methods note every later phase cites (each finding carries a `file:line` or source citation).

**You'll see:** prior-art approaches — classical seasonal decomposition, STL, GAM / spline trend models — with trade-offs.

> Prior art before code.

---

## Phase 2 — Plan

```text
/planning-implementations for an analysis that estimates the warming trend in samples/ocean/buoy_sst.csv after removing the seasonal cycle, with success criteria
```

**Collaborative again.** It reads the research doc, then **presents design options with a recommendation** and a proposed phase breakdown for your approval. When it asks:

- Pick the simplest — **harmonic regression**.
- Reuse the existing `test_generate_buoy_sst.py`; don't add new test files.

It resolves every uncertainty before saving — **no TBDs, no "open questions"** left in the plan.

**Writes:** `docs/rse/specs/plan-<slug>.md` — with **success criteria split into Automated and Manual**. That split is the contract `/validate` checks later.

> A tight plan means a reviewable result.

---

## Phase 3 — Experiment (the centerpiece)

Start a fresh session, then:

```text
/running-experiments compare harmonic regression vs STL decomposition for recovering the warming trend in samples/ocean/buoy_sst.csv
```

**Collaborative.** It confirms the question, picks 2–3 *architecturally distinct* approaches with success criteria, then **builds and runs each for real** (in a scratch dir / temp branch), measures, and recommends one — asking *"proceed, or explore further?"*

**Watch the Iron Law in action:** STL needs `statsmodels`, which isn't installed here. Rather than guess STL's result, the skill labels it an **unverified assumption** and recommends the harmonic regression it actually ran.

**Writes:** `docs/rse/specs/experiment-<slug>.md` — the head-to-head, with a comparison matrix.

> This is where a research claim is earned, not asserted. It's the slow phase — while it runs, read the next two slides.

---

## The experiment Iron Law

**An experiment is real measured code, or it is not an experiment.**

Every approach in the comparison must be actually built and run. A comparison with one side *assumed* —

> "harmonic regression is obviously better, so I didn't run STL"

— is an opinion with a number stapled to one half. For a research result, that is the difference between a finding and a guess. If an approach genuinely can't be built, the skill labels it an *unverified assumption* — never a benchmark.

---

## Phase 4 — Implement

Start a fresh session, then (use the real filename from Phase 2):

```text
/implementing-plans go ahead with docs/rse/specs/plan-<slug>.md
```

**Before any code, it hard-stops to confirm the working branch** — it will **not** build on `main`. Then it implements **phase by phase**, ticking `- [ ]` → `- [x]` in the plan as it goes, running automated checks, and **pausing after each phase for your manual verification** before moving on. If the code doesn't match the plan, it stops and asks.

**Writes (at the end):** `docs/rse/specs/implement-<slug>.md` — what changed, any deviations, and verification results.

> You stay in the loop: nothing advances past a phase without you.

---

## Phase 5 — Validate

Start a fresh session, then:

```text
/validating-implementations docs/rse/specs/plan-<slug>.md
```

**It trusts nothing it didn't see.** Checkmarks and "all tests pass" are claims — so it **re-runs every Automated Verification command itself**, reads the code against each criterion, and assigns an overall **✅ / ⚠️ / ❌**.

**Writes:** `docs/rse/specs/validation-<slug>.md`. The recovered warming slope should land near the documented truth.

**Then, as the human:** check the result against `samples/ocean/GROUND_TRUTH.md` — **≈ 0.03 °C/yr**. (The agent is told not to read that file — *you* are the check.)

> A quality gate, not a vibe check. The known answer is what makes it honest.

---

## Phase 6 — Reproduce

Start a fresh session for reproducibility:

```text
/ensuring-reproducibility of the warming-trend estimate from the samples/ocean experiment
```

**You'll see:** a provenance record — interpreter + `pixi.lock`, code commit, the data's seed and content hash, config, exact commands — captured **and then re-run in a clean environment** to confirm the result holds.

**Where it lands:** the skill **appends a `## Reproducibility` section to the artifact that already holds the result** (the `experiment-` doc here) — only creating `reproducibility-<slug>.md` when there's no artifact to append to.

> A record isn't reproducible until it's been reproduced. Capturing env, seed, and commands is necessary; the clean-room re-run is what turns the claim into a finding.

---

## What you've got now

Six phases later, `docs/rse/specs/` holds a **cross-linked research record**:

```text
research-<slug>.md     ← the methods
plan-<slug>.md         → cites the research
experiment-<slug>.md   → tests the methods (+ ## Reproducibility appended)
implement-<slug>.md    → cites the plan
validation-<slug>.md   → checks the plan's criteria
```

Committed alongside the code, this survives the session and transfers to the next person — hypothesis, evidence, and provenance intact.

> That's the difference from a chat log: a durable, reviewable, reproducible record.

---

## Now test your own hypothesis

- Swap the buoy scenario for **your** data and question — the arc is the same.
- Use **`/creating-handoffs`** to carry full context — git state, artifacts, what's still broken — into a fresh chat when a session gets long.
- When the result must be trustworthy, run **`/hardening-research-code`**: it pins down what *correct* means against an independent reference, then backs it with correctness, stability, and regression tests (a regression baseline alone isn't a correctness check). Here `test_generate_buoy_sst.py` already pins the *data*; this adds the same protection to your *analysis*.
- Put your conventions, data shapes, and "don't read/touch X" in **`.github/copilot-instructions.md`** — that's where your research context lives.

> Same loop, your science. From hypothesis to a result you can defend.
