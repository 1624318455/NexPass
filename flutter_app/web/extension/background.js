// NexPass Chrome Extension — Background Service Worker
// Handles native messaging with the Flutter desktop app and coordinates
// credential fill requests between content script and native host.

const NATIVE_HOST_NAME = 'io.nexpass.native_host';

class NexPassBackground {
  constructor() {
    this.nativePort = null;
    this.pendingRequests = new Map();
    this.connectionStatus = 'disconnected';

    this.initListeners();
    this.connectToNativeHost();
  }

  // ── Initialization ─────────────────────────────────────────────────

  initListeners() {
    // Messages from content scripts (autofill requests)
    chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
      this.handleContentMessage(msg, sender, sendResponse);
      return true; // async response
    });

    // Native host messages
    chrome.runtime.onConnectExternal?.addListener((port) => {
      this.handleNativeConnection(port);
    });

    // Extension install / update
    chrome.runtime.onInstalled.addListener(() => {
      console.log('[NexPass] Extension installed or updated');
      this.connectToNativeHost();
    });
  }

  // ── Native host connection ──────────────────────────────────────────

  connectToNativeHost() {
    try {
      this.nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);

      this.nativePort.onMessage.addListener((response) => {
        this.handleNativeResponse(response);
      });

      this.nativePort.onDisconnect.addListener(() => {
        const error = chrome.runtime.lastError;
        console.warn('[NexPass] Native host disconnected:', error?.message);
        this.connectionStatus = 'disconnected';
        this.nativePort = null;

        // Retry connection after delay
        setTimeout(() => this.connectToNativeHost(), 3000);
      });

      this.connectionStatus = 'connected';
      console.log('[NexPass] Connected to native host');
    } catch (err) {
      console.warn('[NexPass] Failed to connect to native host:', err.message);
      this.connectionStatus = 'disconnected';
    }
  }

  // ── Content script message handling ─────────────────────────────────

  handleContentMessage(message, sender, sendResponse) {
    switch (message.action) {
      case 'requestDeviceBiometrics':
        this.requestCredentials(message.origin, sender.tab?.id)
          .then((result) => sendResponse(result))
          .catch((err) => sendResponse({ success: false, error: err.message }));
        break;

      case 'getStatus':
        sendResponse({
          connected: this.connectionStatus === 'connected',
          status: this.connectionStatus,
        });
        break;

      case 'manualFill':
        this.fillCredentials(message.username, message.password, sender.tab?.id)
          .then((result) => sendResponse(result))
          .catch((err) => sendResponse({ success: false, error: err.message }));
        break;

      default:
        sendResponse({ success: false, error: 'Unknown action' });
    }
  }

  // ── Credential request flow ─────────────────────────────────────────

  async requestCredentials(origin, tabId) {
    if (!this.nativePort) {
      this.connectToNativeHost();
      return { success: false, error: 'Native host not connected' };
    }

    return new Promise((resolve, reject) => {
      const requestId = Date.now().toString();

      // Store pending request
      this.pendingRequests.set(requestId, { resolve, reject, tabId, origin });

      // Send request to native host (Flutter desktop app)
      this.nativePort.postMessage({
        action: 'getCredentials',
        requestId,
        origin,
      });

      // Timeout after 30s
      setTimeout(() => {
        if (this.pendingRequests.has(requestId)) {
          this.pendingRequests.delete(requestId);
          reject(new Error('Request timed out'));
        }
      }, 30000);
    });
  }

  // ── Native host response handling ───────────────────────────────────

  handleNativeResponse(response) {
    const { requestId, credentials, success, error } = response;
    const pending = this.pendingRequests.get(requestId);

    if (!pending) return;

    this.pendingRequests.delete(requestId);

    if (success && credentials) {
      // Forward credentials to content script for autofill
      chrome.tabs.sendMessage(pending.tabId, {
        action: 'populateSecureInput',
        credentials,
      });
      pending.resolve({ success: true });
    } else {
      pending.resolve({ success: false, error: error || 'No credentials returned' });
    }
  }

  // ── Direct credential fill (from popup) ─────────────────────────────

  async fillCredentials(username, password, tabId) {
    if (!tabId) {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      tabId = tab?.id;
    }

    if (!tabId) {
      return { success: false, error: 'No active tab' };
    }

    chrome.tabs.sendMessage(tabId, {
      action: 'populateSecureInput',
      credentials: { username, password },
    });

    return { success: true };
  }
}

// Initialize
new NexPassBackground();
