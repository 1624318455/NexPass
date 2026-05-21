import 'dart:convert';
import '../services/secure_storage_service.dart';

/// Centralized app settings model.
/// Persists to SecureStorage as JSON.
class AppSettings {
  // ── Security ────────────────────────────────────────────────────────
  bool masterPasswordSet;
  bool biometricEnabled;
  String? recoveryQuestion;
  String? recoveryAnswer;

  // ── Autofill ────────────────────────────────────────────────────────
  bool autofillEnabled;

  // ── Theme ───────────────────────────────────────────────────────────
  int themeColorIndex; // 0-5

  // ── Bottom Navigation ───────────────────────────────────────────────
  bool navPasswords;
  bool navAuthenticators;
  bool navCards;
  bool navPasskeys;

  // ── Data Import ─────────────────────────────────────────────────────
  // (No persistent state — import is on-demand)

  // ── Password List ───────────────────────────────────────────────────
  bool showRecentShortcuts;
  bool showFavorites;

  // ── Password Card Display ───────────────────────────────────────────
  bool cardShowUsername;
  bool cardShowWebsite;
  bool cardShowLinkedAuth;
  bool cardHideOtherWhenAuth;

  // ── Authenticator Card Display ──────────────────────────────────────
  bool authShowIssuer;
  bool authShowAccount;
  bool authShowProgressBar;
  bool authSmoothAnimation;

  // ── General ─────────────────────────────────────────────────────────
  String language; // 'system', 'en', 'zh', 'ja'

  AppSettings({
    this.masterPasswordSet = false,
    this.biometricEnabled = false,
    this.recoveryQuestion,
    this.recoveryAnswer,
    this.autofillEnabled = false,
    this.themeColorIndex = 0,
    this.navPasswords = true,
    this.navAuthenticators = true,
    this.navCards = true,
    this.navPasskeys = true,
    this.showRecentShortcuts = true,
    this.showFavorites = false,
    this.cardShowUsername = true,
    this.cardShowWebsite = true,
    this.cardShowLinkedAuth = false,
    this.cardHideOtherWhenAuth = false,
    this.authShowIssuer = true,
    this.authShowAccount = true,
    this.authShowProgressBar = true,
    this.authSmoothAnimation = true,
    this.language = 'system',
  });

  // ── Serialization ───────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'masterPasswordSet': masterPasswordSet,
    'biometricEnabled': biometricEnabled,
    'recoveryQuestion': recoveryQuestion,
    'recoveryAnswer': recoveryAnswer,
    'autofillEnabled': autofillEnabled,
    'themeColorIndex': themeColorIndex,
    'navPasswords': navPasswords,
    'navAuthenticators': navAuthenticators,
    'navCards': navCards,
    'navPasskeys': navPasskeys,
    'showRecentShortcuts': showRecentShortcuts,
    'showFavorites': showFavorites,
    'cardShowUsername': cardShowUsername,
    'cardShowWebsite': cardShowWebsite,
    'cardShowLinkedAuth': cardShowLinkedAuth,
    'cardHideOtherWhenAuth': cardHideOtherWhenAuth,
    'authShowIssuer': authShowIssuer,
    'authShowAccount': authShowAccount,
    'authShowProgressBar': authShowProgressBar,
    'authSmoothAnimation': authSmoothAnimation,
    'language': language,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    masterPasswordSet: json['masterPasswordSet'] ?? false,
    biometricEnabled: json['biometricEnabled'] ?? false,
    recoveryQuestion: json['recoveryQuestion'],
    recoveryAnswer: json['recoveryAnswer'],
    autofillEnabled: json['autofillEnabled'] ?? false,
    themeColorIndex: json['themeColorIndex'] ?? 0,
    navPasswords: json['navPasswords'] ?? true,
    navAuthenticators: json['navAuthenticators'] ?? true,
    navCards: json['navCards'] ?? true,
    navPasskeys: json['navPasskeys'] ?? true,
    showRecentShortcuts: json['showRecentShortcuts'] ?? true,
    showFavorites: json['showFavorites'] ?? false,
    cardShowUsername: json['cardShowUsername'] ?? true,
    cardShowWebsite: json['cardShowWebsite'] ?? true,
    cardShowLinkedAuth: json['cardShowLinkedAuth'] ?? false,
    cardHideOtherWhenAuth: json['cardHideOtherWhenAuth'] ?? false,
    authShowIssuer: json['authShowIssuer'] ?? true,
    authShowAccount: json['authShowAccount'] ?? true,
    authShowProgressBar: json['authShowProgressBar'] ?? true,
    authSmoothAnimation: json['authSmoothAnimation'] ?? true,
    language: json['language'] ?? 'system',
  );

  // ── Persistence ─────────────────────────────────────────────────────

  static const _storageKey = 'app_settings';

  Future<void> save(SecureStorageService storage) async {
    final json = jsonEncode(toJson());
    await storage.write(key: _storageKey, value: json);
  }

  static Future<AppSettings> load(SecureStorageService storage) async {
    final json = await storage.read(_storageKey);
    if (json == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(json));
    } catch (_) {
      return AppSettings();
    }
  }
}
