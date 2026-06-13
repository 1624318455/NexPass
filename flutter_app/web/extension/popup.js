// NexPass Chrome Extension — Popup Script
// Handles UI interactions for the extension popup.

document.addEventListener('DOMContentLoaded', () => {
  const statusDot = document.getElementById('statusDot');
  const statusText = document.getElementById('statusText');
  const usernameInput = document.getElementById('username');
  const passwordInput = document.getElementById('password');
  const fillBtn = document.getElementById('fillBtn');
  const fillMsg = document.getElementById('fillMsg');

  // Check connection status on load
  chrome.runtime.sendMessage({ action: 'getStatus' }, (response) => {
    if (response?.connected) {
      statusDot.classList.add('connected');
      statusText.textContent = 'Connected to NexPass';
      fillBtn.disabled = false;
    } else {
      statusDot.classList.remove('connected');
      statusText.textContent = 'Disconnected — open NexPass desktop app';
      fillBtn.disabled = true;
    }
  });

  // Fill button click handler
  fillBtn.addEventListener('click', () => {
    const username = usernameInput.value.trim();
    const password = passwordInput.value;

    if (!username && !password) {
      showMsg('Please enter credentials to fill', 'error');
      return;
    }

    fillBtn.disabled = true;
    fillBtn.textContent = 'Filling…';

    chrome.runtime.sendMessage(
      { action: 'manualFill', username, password },
      (response) => {
        fillBtn.disabled = false;
        fillBtn.textContent = 'Fill Current Page';

        if (response?.success) {
          showMsg('Credentials filled successfully', 'success');
          passwordInput.value = '';
        } else {
          showMsg(response?.error || 'Fill failed', 'error');
        }
      }
    );
  });

  function showMsg(text, type) {
    fillMsg.textContent = text;
    fillMsg.className = `msg msg-${type}`;
    setTimeout(() => { fillMsg.className = 'hidden'; }, 3000);
  }
});
