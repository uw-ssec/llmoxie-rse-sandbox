const vscode = require("vscode");

const WALKTHROUGH_ID =
  "uw-ssec.llmoxie-sandbox-walkthrough#llmoxieSandboxGetStarted";
// Rotate the suffix when an update should re-show the walkthrough once.
const SHOWN_KEY = "llmoxieWalkthroughShown.v2";

function openDeckCommand(relativePath) {
  return async () => {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
      void vscode.window.showErrorMessage(
        `No workspace folder open — cannot locate ${relativePath}`
      );
      return;
    }
    const deck = vscode.Uri.joinPath(folders[0].uri, relativePath);
    // The Marp extension renders marp:true markdown inside the built-in
    // markdown preview, so showPreview opens the deck as slides directly.
    await vscode.commands.executeCommand("markdown.showPreview", deck);
  };
}

async function activate(context) {
  // Walkthrough step 5 buttons — open each deck straight into slide preview.
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "llmoxie-sandbox-walkthrough.openPackagingDeck",
      openDeckCommand("docs/slides/research-loop.md")
    ),
    vscode.commands.registerCommand(
      "llmoxie-sandbox-walkthrough.openOceanDeck",
      openDeckCommand("docs/slides/research-loop-ocean.md")
    )
  );

  // Open the walkthrough automatically the first time this Codespace loads
  // with the extension active; after that, it stays reachable from the
  // Welcome page (Help > Welcome) without reopening on every launch.
  if (context.globalState.get(SHOWN_KEY)) {
    return;
  }
  await context.globalState.update(SHOWN_KEY, true);

  // Give the walkthrough sole focus: close all editors, the bottom panel
  // (terminal), the secondary side bar (Copilot Chat), and the primary side
  // bar. Best effort — a failing close must not block the walkthrough.
  const tidy = [
    "workbench.action.closeAllEditors",
    "workbench.action.closePanel",
    "workbench.action.closeAuxiliaryBar",
    "workbench.action.closeSidebar",
  ];
  for (const command of tidy) {
    try {
      await vscode.commands.executeCommand(command);
    } catch {
      // ignore — layout cleanup is cosmetic
    }
  }

  await vscode.commands.executeCommand(
    "workbench.action.openWalkthrough",
    WALKTHROUGH_ID,
    false
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
