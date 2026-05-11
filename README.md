# llmaven-rse-sandbox

This repository contains the sandbox environment for the NAIRR RSE Plugins Demo.

It provides a preconfigured GitHub Codespaces workspace where authorized users can evaluate Research Software Engineering (RSE) AI workflows using GitHub Copilot Chat, the LLMaven Copilot Provider extension, and the UW SSEC RSE Agent Plugins.

## What this repo provides

- A user-facing evaluation environment for research software engineering (RSE) AI workflows
- A GitHub Codespaces sandbox with scientific Python tooling managed by Pixi
- A pinned LLMaven Copilot Provider extension for routing Copilot-compatible requests through the LLMaven / LiteLLM gateway
- Copilot CLI marketplace registration for UW SSEC RSE Agent Plugins
- Guided documentation for first-time demo users

## How the pieces fit together

The sandbox uses three layers:

```text
GitHub Codespaces
  → provides the reproducible development environment

LLMaven Copilot Provider
  → routes Copilot Chat model requests through the LLMaven / LiteLLM gateway

RSE Agent Plugins
  → provide RSE-specific skills, agents, and slash commands via the Copilot CLI marketplace
```

The Copilot provider extension and the RSE Agent Plugins are separate. The provider handles model routing. The plugins provide the research software engineering capabilities.

## Sandbox walkthrough

Follow these steps to go from opening the sandbox to your first successful RSE workflow interaction.

### Step 1 — Open the Codespace

Start from the authorized onboarding flow or from the repository page and open a GitHub Codespace for this repository.

During first launch, the devcontainer automatically:

- prepares the Pixi Python environment
- downloads and verifies the pinned LLMaven Copilot Provider VSIX
- installs the provider extension and configures it to route through the LLMaven / LiteLLM gateway
- installs the Copilot CLI, wires it to the LLMaven gateway, and registers the RSE plugin marketplace

You will see setup output in the terminal during first launch. Wait for it to complete before continuing.

### Step 2 — Start with Copilot Chat (chat-first)

**Begin in Copilot Chat, not the CLI.** Chat is the fastest way to verify that the full stack is working end-to-end before switching to command-line workflows.

Open the Copilot Chat panel in VS Code (the speech-bubble icon in the Activity Bar, or `Ctrl+Shift+I`).

Try a simple prompt to confirm the connection is live:

```text
What is this repository for?
```

If Copilot Chat responds with a description of the sandbox, the provider and gateway are working.

### Step 3 — Select a model

Open the model picker inside Copilot Chat (the model name shown near the input box).

OAI-compatible models routed through the LLMaven gateway will appear alongside standard GitHub Copilot models. Select one of the OAI-compatible models to route requests through the LLMaven / LiteLLM gateway.

See the [Copilot model picker screenshot](docs/assets/copilot-model-picker.png).

![Copilot Chat model picker showing OAI-compatible models](docs/assets/copilot-model-picker.png)

### Step 4 — Explore freely in Copilot Chat

With a model selected, use Copilot Chat for open-ended, conversational work — exploring unfamiliar code, asking design questions, or drafting changes interactively.

```text
What scientific Python packages are available in this workspace, and how is the environment managed?
```

```text
Summarize the structure of the files under samples/ and flag any obvious issues.
```

Note: the UW SSEC RSE Agent Plugins are installed as Copilot **CLI** plugins, not Chat plugins. To invoke plugin-backed workflows (research, planning, handoff, validation), move to the Copilot CLI in Step 5.

### Step 5 — Use the Copilot CLI for RSE plugin workflows

The standalone Copilot CLI is installed in the devcontainer, pre-wired to the LLMaven gateway, and the `uw-ssec/rse-plugins` marketplace is registered. The CLI is the surface where the RSE Agent Plugins (slash commands, agents, skills) are available.

**When to stay in Chat:**

- Exploring unfamiliar code or tooling interactively
- Back-and-forth design and Q&A

**When to move to the CLI:**

- Invoking RSE Agent Plugin slash commands
- Running plugin-backed tasks non-interactively in a script or CI context
- Piping Copilot output into other shell tools

Start an interactive session from the terminal:

```text
copilot
```

The CLI is pinned to `gpt-5.3-codex` (set via `COPILOT_MODEL`) — it is the only model qualified for the CLI-driven RSE plugin workflows in this sandbox. Do not switch the CLI model with `/model`. Model selection in Copilot Chat (Step 3) is a separate surface and is unaffected.

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

Other commands provided by the plugin: `/experiment`, `/handoff`, `/implement`, `/iterate-plan`.

## Saving your work

This repository is intended as a managed sandbox. Demo users should fork this repository if they want to preserve changes outside the provided environment.

See:

```text
docs/save-your-work.md
```

## Data and evaluation notes

AI interactions in this environment may be routed through the LLMaven / LiteLLM gateway for research and evaluation purposes.

See:

```text
docs/data-collection.md
```

## Trust assumptions

This sandbox installs a pinned LLMaven Copilot Provider VSIX during devcontainer setup. The VSIX is verified against a SHA256 value committed in this repository before installation.

The provider extension uses a gateway credential provisioned through the authorized onboarding flow. Use this sandbox only from trusted Codespace sessions created through that flow.
