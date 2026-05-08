# llmaven-rse-sandbox

This repository contains the sandbox environment for the NAIRR RSE Plugins Demo.

It provides a preconfigured GitHub Codespaces workspace where authorized users can evaluate Research Software Engineering (RSE) AI workflows using GitHub Copilot Chat, the LLMaven Copilot Provider extension, and the UW SSEC RSE Agent Plugins.

## What this repo provides

- A user-facing evaluation environment for research software engineering (RSE) AI workflows
- A GitHub Codespaces sandbox with scientific Python tooling managed by Pixi
- A pinned LLMaven Copilot Provider extension for routing Copilot-compatible requests through the LLMaven / LiteLLM gateway
- Workspace recommendations for UW SSEC RSE Agent Plugins
- Guided documentation for first-time demo users

## How the pieces fit together

The sandbox uses three layers:

```text
GitHub Codespaces
  → provides the reproducible development environment

LLMaven Copilot Provider
  → routes Copilot Chat model requests through the LLMaven / LiteLLM gateway

RSE Agent Plugins
  → provide RSE-specific skills, agents, and workflows inside Copilot Chat
```

See the [three-layer sandbox view](docs/assets/sandbox-three-layer-view.png), which shows the RSE Agent Plugins list, the LLMaven Copilot Provider extension, and the Copilot Chat model picker in one VS Code workspace.

![Three-layer sandbox view showing RSE Agent Plugins, the LLMaven Copilot Provider, and Copilot Chat](docs/assets/sandbox-three-layer-view.png)

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

### Step 4 — Try an RSE workflow in Copilot Chat

With the plugins installed and a model selected, try a workflow prompt in Copilot Chat:

```text
Use the scientific-python-development plugin to review this repository for testing, dependency, and API design issues.
```

```text
Use the project-management plugin to assess onboarding and handoff readiness for this repository.
```

```text
Use the research-software-design plugin to identify user, workflow, and design risks in this project.
```

The plugin provides RSE-specific skills, agents, or slash commands that appear inside Copilot Chat.

### Step 5 — Move to the Copilot CLI for scripted workflows

Once the Chat interaction is working, use the Copilot CLI for workflows that benefit from shell integration, file output, or scripted repetition.

**When to stay in Chat:**

- Exploring unfamiliar code or tooling
- Interactive back-and-forth questions
- Plugin discovery and testing new workflows

**When to move to the CLI:**

- Automating a repeated workflow across multiple files or repositories
- Piping Copilot output into other shell tools
- Running plugin-backed tasks non-interactively in a script or CI context

The Copilot CLI is installed in the devcontainer, pre-wired to the LLMaven gateway, and the RSE plugin marketplace is registered. The default model is `gpt-5.3-codex`.

Start a chat session from the terminal:

```text
gh copilot chat
```

Switch models in-session using the `/model` slash command:

```text
/model gpt-5.4-mini
/model gpt-oss-120b
```

For the full setup details and troubleshooting, see [docs/getting-started.md](docs/getting-started.md).

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
