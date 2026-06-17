const vscode = require("vscode");

const WALKTHROUGH_ID =
  "uw-ssec.llmoxie-sandbox-walkthrough#llmoxieSandboxGetStarted";
// Rotate the suffix when an update should re-show the walkthrough once.
const SHOWN_KEY = "llmoxieWalkthroughShown.v4";
const BROWSER_TIP_KEY = "llmoxieBrowserTipShown";

// Classify the current browser for the "Check your browser" step and the
// startup tip. Copilot Chat works best in Chromium browsers. The user agent
// is only visible when this extension runs in the web worker host (VS Code
// Web); when it runs remotely or in the desktop app, navigator is Node's stub
// and the browser can't be determined.
//   "ok"          — Chromium-based browser (Chrome, Edge, etc.)
//   "unsupported" — Firefox or non-Chromium Safari
//   "unknown"     — can't tell (desktop app or remote host)
function detectBrowser() {
  if (vscode.env.uiKind !== vscode.UIKind.Web) {
    return "unknown";
  }
  if (typeof navigator === "undefined" || !navigator.userAgent) {
    return "unknown";
  }
  const ua = navigator.userAgent;
  const isFirefox = ua.includes("Firefox/");
  const isNonChromiumSafari =
    ua.includes("Safari/") && !ua.includes("Chrome/") && !ua.includes("Chromium/");
  if (isFirefox || isNonChromiumSafari) {
    return "unsupported";
  }
  return "ok";
}

async function maybeShowBrowserTip(context) {
  if (context.globalState.get(BROWSER_TIP_KEY)) {
    return;
  }
  if (detectBrowser() !== "unsupported") {
    return;
  }
  await context.globalState.update(BROWSER_TIP_KEY, true);
  void vscode.window.showWarningMessage(
    "This sandbox's Copilot Chat works best in Google Chrome — you may hit hiccups in this browser."
  );
}

// Explicit, on-demand browser check wired to the walkthrough step button.
// Unlike the startup tip, this always reports a result so the step gives
// clear feedback whether the browser is supported or not.
async function checkBrowserCommand() {
  switch (detectBrowser()) {
    case "ok":
      void vscode.window.showInformationMessage(
        "Browser check passed — Copilot Chat is well supported in this Chromium-based browser."
      );
      break;
    case "unsupported":
      void vscode.window.showWarningMessage(
        "This sandbox's Copilot Chat works best in Google Chrome — you may hit hiccups in this browser. Reopen this Codespace in Chrome for the smoothest experience."
      );
      break;
    default:
      void vscode.window.showInformationMessage(
        "Can't detect the browser from here — you're likely in the VS Code desktop app or a remote host. If you're working in a browser, use Google Chrome for the best Copilot Chat experience."
      );
  }
}

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
  // Walkthrough "Open the deck" button — open the deck straight into slide preview.
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "llmoxie-sandbox-walkthrough.openOceanDeck",
      openDeckCommand("docs/slides/research-loop-ocean.md")
    )
  );

  // Walkthrough "Check your browser" button.
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "llmoxie-sandbox-walkthrough.checkBrowser",
      checkBrowserCommand
    )
  );

  await maybeShowBrowserTip(context);

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
