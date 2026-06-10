# LLMoxie NAIRR Sandbox

[![Part of NAIRR Pilot](https://img.shields.io/badge/Part_of-NAIRR_Pilot-0d4f8c?style=for-the-badge)](https://nairrpilot.org/) [![NAIRR Pilot award NAIRR240292](https://img.shields.io/badge/Award-NAIRR240292-0d4f8c?style=for-the-badge)](https://nairrpilot.org/projects/awarded?_requestNumber=NAIRR240292) [![Start the Sandbox walkthrough](https://img.shields.io/badge/Start-Sandbox%20walkthrough-2ea44f?style=for-the-badge)](#sandbox-walkthrough)

<h1 align="center">⏳ Hold on — your sandbox is setting up</h1>

<p align="center"><b>First launch takes a few minutes while the devcontainer prepares the pixi Python
environment, the LLMoxie Model Provider, and the Copilot CLI with the RSE plugins.<br>
Watch the terminal — when the setup output finishes, the LLMoxie RSE Sandbox
walkthrough opens automatically and takes it from there.</b></p>

<p align="center">💡 Working in the browser? Copilot Chat works best in <b>Google Chrome</b>.</p>

---

This repository is a **NAIRR Pilot Sandbox** for exploring AI-assisted Research Software Engineering (RSE) workflows.

NAIRR Pilot Sandbox projects are for any US-based researcher, educator, or student interested in exploring an AI-related example project in a test environment. These Sandboxes are isolated environments for experimentation and development. They allow academics, scientists, and students to try out new features or server configurations, or just play with AI tools without impacting the live system. Think of a sandbox as a playground where you can experiment with different AI tools and ideas without breaking anything that's already working.

This specific sandbox provides a preconfigured GitHub Codespaces workspace for evaluating RSE AI workflows using GitHub Copilot Chat, the LLMoxie Model Provider extension, and the UW SSEC RSE Agent Plugins.

## What this repo provides

- A user-facing evaluation environment for research software engineering (RSE) AI workflows
- A GitHub Codespaces sandbox with scientific Python tooling managed by Pixi
- A pinned LLMoxie Model Provider extension for routing Copilot-compatible requests through the LLMoxie / LiteLLM gateway
- Copilot CLI marketplace registration for UW SSEC RSE Agent Plugins
- Copilot Chat prompt files (`.github/prompts/`) that expose the RSE workflow slash commands — `/research`, `/plan`, `/implement`, `/validate`, `/experiment`, `/reproduce`, `/iterate-plan`, `/harden`, `/handoff` — directly in the Chat panel
- A first-run **Get Started walkthrough** (a first-party VS Code extension built from `.devcontainer/sandbox-walkthrough/`) that opens automatically and covers model selection, gateway verification, a first prompt, and the guided decks
- A gateway health check — `pixi run verify` — also wired to the walkthrough's "Verify the gateway" button
- Two guided Marp slide decks (`docs/slides/`) that drive the research loop in Copilot Chat, slide by slide

## How the pieces fit together

The sandbox uses four layers:

```text
GitHub Codespaces
  → provides the reproducible development environment

LLMoxie Model Provider
  → routes Copilot Chat model requests through the LLMoxie / LiteLLM gateway

RSE Agent Plugins
  → provide RSE-specific skills, agents, and slash commands

Sandbox walkthrough
  → first-run onboarding: select a model, verify the gateway, open the decks
```

The Copilot provider extension and the RSE Agent Plugins are separate. The provider handles model routing. The plugins provide the research software engineering capabilities, reachable from two surfaces: slash commands in Copilot Chat (backed by the prompt files in `.github/prompts/`, which hand off to the plugin skills) and the Copilot CLI (via the registered plugin marketplace).

Although the application layer is built on Claude Code plugins, we have enabled it on this sandbox as the GitHub Copilot CLI. You can therefore use GitHub's Copilot Coding Agent with OpenAI's GPT models, served through Microsoft Foundry and supported by our NAIRR allocation.

## Sandbox walkthrough

Open a GitHub Codespace for this repository, starting from the authorized
onboarding flow or the repository page. Once setup finishes (watch for the
green **SANDBOX READY** banner in the terminal), the **LLMoxie RSE Sandbox
walkthrough** opens automatically and walks you through everything — selecting
a UW SSEC model, verifying the gateway, sending your first prompt, and opening
the guided research-loop decks. Reopen it anytime via
**Help → Welcome → LLMoxie RSE Sandbox**.

The walkthrough's "Verify the gateway" button runs the same check that is
available from any terminal:

```bash
pixi run verify
```

> **Prefer a guided, slide-by-slide demo?** Complete the walkthrough's
> model-selection step first, then open `docs/slides/research-loop.md` and choose
> "Open Preview to the Side" (Marp). It walks you through the full `ai-research-workflows`
> research loop in Copilot Chat — packaging the `samples/` climate scripts — with each
> instruction on screen beside the chat panel.
>
> **Prefer a research story?** `docs/slides/research-loop-ocean.md` tells the same loop as a
> hypothesis-driven oceanographic arc — testing a warming trend in synthetic buoy data — and
> features the `/experiment` and `/reproduce` phases the packaging deck skips.

### Working in Copilot Chat

With a UW SSEC model selected, Copilot Chat handles open-ended, conversational
work — exploring unfamiliar code, design questions, drafting changes.

The RSE workflow slash commands work directly in Chat: typing `/research`,
`/plan`, `/implement`, `/validate`, `/experiment`, `/reproduce`,
`/iterate-plan`, `/harden`, or `/handoff` runs the matching prompt file from
`.github/prompts/`, which hands off to the corresponding RSE Agent Plugin
skill. This is the surface the guided decks in `docs/slides/` use.

### Using the Copilot CLI for RSE plugin workflows

The standalone Copilot CLI is installed in the devcontainer, pre-wired to the
LLMoxie gateway, and the `uw-ssec/rse-plugins` marketplace is registered. The
CLI loads the RSE Agent Plugins (slash commands, agents, skills) directly from
that marketplace — the same workflows the Chat prompt files hand off to. Move
to the CLI for non-interactive use in a script or CI context, or to pipe
Copilot output into other shell tools.

Start an interactive session from the terminal:

```text
copilot
```

The CLI is pinned to `gpt-5.3-codex` (set via `COPILOT_MODEL`) — it is the only model qualified for the CLI-driven RSE plugin workflows in this sandbox. Do not switch the CLI model with `/model`. Model selection in Copilot Chat is a separate surface and is unaffected.

Try an RSE Agent Plugin slash command (provided by `ai-research-workflows@rse-plugins`):

```text
/research What testing, dependency, and API design issues exist in this repository?
```

```text
/plan Draft a roadmap to improve onboarding and handoff readiness for this project.
```

```text
/validate Identify user, workflow, and design risks in this project.
```

Other commands provided by the plugin: `/experiment`, `/handoff`, `/harden`, `/implement`, `/iterate-plan`, `/reproduce`.

## Saving your work

This repository is a managed sandbox with restricted write access. To preserve your work outside the provided environment:

1. Fork this repository to your own GitHub account
2. Add your fork as a remote if needed
3. Commit and push your changes to your fork

This keeps the shared sandbox source clean while letting you preserve your own work.

**Heads-up — forking does not carry gateway access.** The LLMoxie / LiteLLM gateway credentials are provisioned for this sandbox specifically and are not part of the repository contents. A GitHub Codespace launched from your own fork will not have those credentials, so Copilot Chat and the Copilot CLI in that Codespace will not be able to route requests through the UW SSEC models. Use the sandbox Codespace for AI-routed workflows; use your fork to preserve code changes.

## Data and evaluation notes

AI interactions in this environment may be routed through the LLMoxie / LiteLLM gateway for research and evaluation purposes. The intended design is to support de-identified logging using session-level identifiers rather than personal identity.

## Trust assumptions

This sandbox installs a pinned LLMoxie Model Provider VSIX during devcontainer setup. The VSIX is verified against a SHA256 value committed in this repository before installation.

The Get Started walkthrough extension is first-party: it is packaged during setup from the source committed at `.devcontainer/sandbox-walkthrough/` — nothing is downloaded for it.

The provider extension uses a gateway credential provisioned through the authorized onboarding flow. Use this sandbox only from trusted Codespace sessions created through that flow.

## Acknowledgements

LLMoxie is developed by the [University of Washington Scientific Software Engineering Center (UW SSEC)](https://escience.washington.edu/software-engineering/ssec/) at the [eScience Institute](https://escience.washington.edu/).

This work is supported by the U.S. National Science Foundation (NSF) through [NAIRR Pilot award #240292](https://nairrpilot.org/projects/awarded?_requestNumber=NAIRR240292), and by [Schmidt Sciences](https://www.schmidtsciences.org/) through the [Virtual Institutes for Scientific Software (VISS)](https://www.schmidtsciences.org/viss/) program.
