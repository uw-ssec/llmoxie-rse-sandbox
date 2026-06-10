const vscode = require("vscode");

const WALKTHROUGH_ID =
  "uw-ssec.llmoxie-sandbox-walkthrough#llmoxieSandboxGetStarted";
const SHOWN_KEY = "llmoxieWalkthroughShown";

async function activate(context) {
  // Open the walkthrough automatically the first time this Codespace loads
  // with the extension active; after that, it stays reachable from the
  // Welcome page (Help > Welcome) without reopening on every launch.
  if (context.globalState.get(SHOWN_KEY)) {
    return;
  }
  await context.globalState.update(SHOWN_KEY, true);
  await vscode.commands.executeCommand(
    "workbench.action.openWalkthrough",
    WALKTHROUGH_ID,
    false
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
