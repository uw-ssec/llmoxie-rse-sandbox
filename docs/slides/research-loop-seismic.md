---
marp: true
theme: sandbox
paginate: true
title: "Test a Seismic-Hazard Hypothesis with the Research Loop"
description: "LLMoxie NAIRR Sandbox — ai-research-workflows seismology research arc"
---

<!-- _class: lead -->

# Test a Seismic-Hazard Hypothesis with the Research Loop

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
- This deck is open in **Marp preview** — `research-loop-seismic.md` → "Open Preview to the Side".
- The **Copilot Chat** panel is open beside the preview (`Ctrl+Shift+I`).

You'll read a slide, type its prompt in Chat, then open the artifact it writes.

> The artifacts in `docs/rse/specs/` are the *reasoning* trail. git is the *code* trail. Together they keep you in control.

---

## The scenario: is this region prone to large quakes?

Under `samples/seismic/` — one region's ~10 years of recorded earthquakes:

- `earthquake_catalog.csv` — the data (`time`, `magnitude`)
- `GROUND_TRUTH.md` — the **ground truth** (b ≈ 0.8), humans only; the agent won't read it

**Hypothesis:** the region's Gutenberg–Richter b-value sits *below* the global ~1.0 baseline — relatively more large quakes per small one. **Goal:** recover the b-value and check it against that baseline. Run the loop, then check the result against the ground truth.

> Synthetic data with a documented structure, so the answer is checkable. On real data the outcome is genuinely uncertain — that's when the experiment earns its keep.

---

## Phase 1 — Research

In Copilot Chat, type:

```text
/researching I'd like to figure out methods to estimate the Gutenberg–Richter b-value (the magnitude–frequency slope) of an earthquake catalog, for samples/seismic/earthquake_catalog.csv
```

**Collaborative — it scopes before it searches.** Answer: *codebase, prior art, or both?* → **both**; *depth?* → **Moderate**. It then OKs a short plan, investigates, and asks you to review the doc.

**Writes:** `docs/rse/specs/research-<slug>.md` — prior-art approaches (maximum likelihood / Aki–Utsu, least-squares on the frequency–magnitude distribution, the b-positive method) with trade-offs and citations.

> Prior art before code.

---

## Phase 2 — Plan

```text
/planning-implementations estimate the Gutenberg–Richter b-value in samples/seismic/earthquake_catalog.csv above its completeness magnitude, with success criteria
```

**Collaborative.** It reads the research doc, then offers design options + a recommendation and a phase breakdown to approve. Pick **Aki–Utsu maximum likelihood**; reuse the existing `test_generate_catalog.py`. It leaves **no TBDs or open questions**.

**Writes:** `docs/rse/specs/plan-<slug>.md` — success criteria **split into Automated and Manual**, the contract `/validate` checks later.

> A tight plan means a reviewable result.

---

## Phase 3 — Experiment (the centerpiece)

Start a fresh session, then:

```text
/running-experiments compare maximum-likelihood (Aki–Utsu) vs least-squares estimation of the b-value in samples/seismic/earthquake_catalog.csv
```

**Collaborative.** It picks 2–3 *distinct* approaches and **builds and runs each for real**, then recommends one with evidence.

Here a bootstrap confidence interval would need `obspy` (not installed) — so it labels that an **unverified assumption** rather than guess, and recommends the Aki–Utsu estimator it ran; the least-squares fit it also ran comes out sensitive to the magnitude range and off from the stable MLE.

**Writes:** `docs/rse/specs/experiment-<slug>.md` — the head-to-head comparison.

> The slow phase — while it runs, read the next two slides.

---

## The experiment Iron Law

**An experiment is real measured code, or it is not an experiment.**

Every approach in the comparison must be actually built and run. A comparison with one side *assumed* —

> "Aki–Utsu is obviously better, so I didn't run the least-squares fit"

— is an opinion with a number stapled to one half. For a research result, that is the difference between a finding and a guess. If an approach genuinely can't be built, the skill labels it an *unverified assumption* — never a benchmark.

---

## Phase 4 — Implement

Start a fresh session (use the real filename from Phase 2):

```text
/implementing-plans go ahead with docs/rse/specs/plan-<slug>.md
```

**It hard-stops to confirm the branch** — never builds on `main`. Then it works **phase by phase**, ticking `- [ ]` → `- [x]` live, running checks, and **pausing after each phase for your manual verification**.

**Writes (at the end):** `docs/rse/specs/implement-<slug>.md` — changes, deviations, results.

> Nothing advances past a phase without you.

---

## Phase 5 — Validate

Start a fresh session, then:

```text
/validating-implementations docs/rse/specs/plan-<slug>.md
```

**It trusts nothing it didn't see** — it **re-runs every Automated Verification command itself** and reads the code against each criterion, then grades **✅ / ⚠️ / ❌**.

**Writes:** `docs/rse/specs/validation-<slug>.md`.

**You check (human):** the result vs `samples/seismic/GROUND_TRUTH.md` — **b ≈ 0.8**, below the 1.0 baseline. The agent won't read that file.

> A quality gate, not a vibe check.

---

## Phase 6 — Reproduce

Start a fresh session for reproducibility:

```text
/ensuring-reproducibility of the b-value estimate from the samples/seismic experiment
```

**You'll see:** a provenance record — interpreter + `pixi.lock`, commit, data seed + hash, config, exact commands — **then re-run in a clean environment** to confirm it holds.

**Where it lands:** it **appends a `## Reproducibility` section** to the result doc (the `experiment-` doc), creating `reproducibility-<slug>.md` only if there's nothing to append to.

> A record isn't reproducible until it's been reproduced.

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

- Swap the earthquake-catalog scenario for **your** data and question — the arc is the same.
- Use **`/creating-handoffs`** to carry full context — git state, artifacts, open issues — into a fresh chat when a session gets long.
- For a result that must hold up, run **`/hardening-research-code`**: it nails down what *correct* means against an independent reference, then backs it with correctness, stability, and regression tests — pinning your *analysis* the way `test_generate_catalog.py` pins the *data*.
- Put your conventions and "don't read/touch X" rules in **`.github/copilot-instructions.md`**.

> Same loop, your science. From hypothesis to a result you can defend.
