class NexAutofillEngine {
  constructor() {
    this.detectCredentialsForm();
    chrome.runtime.onMessage.addListener(this.handleIncomingAutofill.bind(this));
  }

  detectCredentialsForm() {
    const usernameInput = document.querySelector('input[type="text"][autocomplete*="user"], input[type="email"]');
    const passwordInput = document.querySelector('input[type="password"]');

    if (usernameInput || passwordInput) {
      const buttonBadge = document.createElement('div');
      buttonBadge.className = 'nexpass-autofill-badge';
      buttonBadge.innerHTML = '<img src="' + chrome.runtime.getURL('assets/shield-32.png') + '" />';

      if (passwordInput && passwordInput.parentElement) {
        passwordInput.parentElement.style.position = 'relative';
        passwordInput.parentElement.appendChild(buttonBadge);

        buttonBadge.addEventListener('click', () => {
          chrome.runtime.sendMessage({
            action: "requestDeviceBiometrics",
            origin: window.location.origin
          });
        });
      }
    }
  }

  handleIncomingAutofill(message) {
    if (message.action === "populateSecureInput" && message.credentials) {
      const usernameInput = document.querySelector('input[type="text"], input[type="email"]');
      const passwordInput = document.querySelector('input[type="password"]');

      if (usernameInput) usernameInput.value = message.credentials.username;
      if (passwordInput) passwordInput.value = message.credentials.password;
    }
  }
}

new NexAutofillEngine();
