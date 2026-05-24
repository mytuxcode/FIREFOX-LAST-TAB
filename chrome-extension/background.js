// Keep Last Tab — Chrome (Manifest V3) equivalent of Firefox's
// browser.tabs.closeWindowWithLastTab = false.
//
// When you close the last tab in a normal window, Chrome would normally close
// the whole window. This service worker detects that case and immediately
// opens a fresh new tab in the same window, keeping it alive.
//
// Strategy: keep a live, in-memory count of tabs per window so the decision in
// onRemoved is synchronous. Acting synchronously matters — the window is being
// torn down, and the new tab has to be requested before that finishes.

const STORAGE_AREA = "sync";
const ENABLED_KEY = "enabled";

let enabled = true;
let tabCounts = {}; // windowId -> number of tabs

function rebuildCounts() {
  chrome.windows.getAll({ populate: true }, (windows) => {
    if (chrome.runtime.lastError) return;
    const next = {};
    for (const win of windows) {
      if (win.type === "normal") next[win.id] = win.tabs ? win.tabs.length : 0;
    }
    tabCounts = next;
  });
}

function loadSetting() {
  chrome.storage[STORAGE_AREA].get({ [ENABLED_KEY]: true }, (data) => {
    if (chrome.runtime.lastError) return;
    enabled = data[ENABLED_KEY] !== false;
  });
}

// Initialize on every service-worker wake, plus the explicit lifecycle events.
loadSetting();
rebuildCounts();
chrome.runtime.onInstalled.addListener(rebuildCounts);
chrome.runtime.onStartup.addListener(rebuildCounts);

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === STORAGE_AREA && changes[ENABLED_KEY]) {
    enabled = changes[ENABLED_KEY].newValue !== false;
  }
});

chrome.tabs.onCreated.addListener((tab) => {
  if (tab.windowId == null) return;
  tabCounts[tab.windowId] = (tabCounts[tab.windowId] || 0) + 1;
});

chrome.tabs.onAttached.addListener((_tabId, info) => {
  tabCounts[info.newWindowId] = (tabCounts[info.newWindowId] || 0) + 1;
});

chrome.tabs.onDetached.addListener((_tabId, info) => {
  if (tabCounts[info.oldWindowId]) {
    tabCounts[info.oldWindowId] = Math.max(0, tabCounts[info.oldWindowId] - 1);
  }
});

chrome.windows.onRemoved.addListener((windowId) => {
  delete tabCounts[windowId];
});

chrome.tabs.onRemoved.addListener((_tabId, removeInfo) => {
  const { windowId, isWindowClosing } = removeInfo;
  const countBeforeRemoval = tabCounts[windowId];

  if (tabCounts[windowId]) {
    tabCounts[windowId] = Math.max(0, tabCounts[windowId] - 1);
  }

  // The window is already being torn down for another reason (e.g. the user
  // closed the window itself); nothing for us to keep alive.
  if (isWindowClosing) {
    delete tabCounts[windowId];
    return;
  }

  if (!enabled) return;

  // This removal emptied the window — open a fresh tab to keep it open.
  if (countBeforeRemoval === 1) {
    chrome.tabs.create({ windowId }, () => {
      // If the window was destroyed before the tab could be created, swallow
      // the error; there is nothing left to attach the new tab to.
      void chrome.runtime.lastError;
    });
  }
});
