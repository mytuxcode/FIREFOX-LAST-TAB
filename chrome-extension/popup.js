const ENABLED_KEY = "enabled";

const toggle = document.getElementById("toggle");
const status = document.getElementById("status");

function render(isEnabled) {
  toggle.checked = isEnabled;
  status.textContent = isEnabled
    ? "On — your window stays open when you close the last tab."
    : "Off — Chrome's default behavior (last tab closes the window).";
}

chrome.storage.sync.get({ [ENABLED_KEY]: true }, (data) => {
  render(data[ENABLED_KEY] !== false);
});

toggle.addEventListener("change", () => {
  const isEnabled = toggle.checked;
  chrome.storage.sync.set({ [ENABLED_KEY]: isEnabled }, () => {
    render(isEnabled);
  });
});
