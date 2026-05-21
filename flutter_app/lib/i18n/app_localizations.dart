import 'package:flutter/material.dart';

import 'l10n_en.dart';
import 'l10n_zh.dart';
import 'l10n_ja.dart';

/// Lightweight i18n system using map-based translations.
/// Access via `S.of(context).someString` or `S.current.someString`.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('zh'), Locale('ja')];

  String get(String key) => _strings[key] ?? key;

  // ── App ──────────────────────────────────────────────────────────────

  String get appTitle => get('appTitle');
  String get vaultSubtitle => get('vaultSubtitle');

  // ── Main screen ──────────────────────────────────────────────────────

  String get searchHint => get('searchHint');
  String get tabAll => get('tabAll');
  String get tabLogins => get('tabLogins');
  String get tabCards => get('tabCards');
  String get tabNotes => get('tabNotes');
  String get vaultEmpty => get('vaultEmpty');
  String get vaultEmptyHint => get('vaultEmptyHint');
  String get noItemsInCategory => get('noItemsInCategory');
  String get passwordCopied => get('passwordCopied');
  String get passwordReadyToPaste => get('passwordReadyToPaste');
  String get quickPaste => get('quickPaste');
  String get securityAudit => get('securityAudit');
  String get generator => get('generator');

  // ── Add / Delete dialogs ─────────────────────────────────────────────

  String get deleteTitle => get('deleteTitle');
  String deleteConfirm(String name) => get('deleteConfirm').replaceAll('{name}', name);
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get addCredential => get('addCredential');
  String get nameLabel => get('nameLabel');
  String get usernameLabel => get('usernameLabel');
  String get passwordLabel => get('passwordLabel');
  String get typeLogin => get('typeLogin');
  String get typeCard => get('typeCard');
  String get typeNote => get('typeNote');
  String get add => get('add');

  // ── Password generator ───────────────────────────────────────────────

  String get passwordGenerator => get('passwordGenerator');
  String get excellent => get('excellent');
  String get strong => get('strong');
  String get fair => get('fair');
  String strengthLabel(String label) => get('strengthLabel').replaceAll('{label}', label);
  String get close => get('close');
  String get regenerate => get('regenerate');

  // ── Clipboard overlay ────────────────────────────────────────────────

  String get dualClipboardActive => get('dualClipboardActive');
  String get totpToClipboard => get('totpToClipboard');
  String get passwordToRam => get('passwordToRam');
  String clipboardCountdown(int seconds) =>
      get('clipboardCountdown').replaceAll('{seconds}', '$seconds');

  // ── Security audit ───────────────────────────────────────────────────

  String get fixAll => get('fixAll');
  String get fixing => get('fixing');
  String get noAuditData => get('noAuditData');
  String fixedCount(int count) => get('fixedCount').replaceAll('{count}', '$count');
  String get good => get('good');
  String get poor => get('poor');
  String get critical => get('critical');

  // Health descriptions
  String get healthExcellent => get('healthExcellent');
  String get healthGood => get('healthGood');
  String get healthFair => get('healthFair');
  String get healthPoor => get('healthPoor');
  String get healthCritical => get('healthCritical');

  // Stats
  String get statPasswords => get('statPasswords');
  String get statWeak => get('statWeak');
  String get statReused => get('statReused');

  // Issues
  String get allClear => get('allClear');
  String get noIssuesFound => get('noIssuesFound');
  String get issuesFound => get('issuesFound');
  String get severityCritical => get('severityCritical');
  String get severityWarning => get('severityWarning');
  String get generateStrongPassword => get('generateStrongPassword');
  String get healthLabel => get('healthLabel');

  // Onboarding
  String get onboardingSkip => get('onboardingSkip');
  String get onboardingNext => get('onboardingNext');
  String get settings => get('settings');
  String get settingsGeneral => get('settingsGeneral');
  String get settingsLanguage => get('settingsLanguage');
  String get settingsSync => get('settingsSync');
  String get settingsWebDAV => get('settingsWebDAV');
  String get settingsWebDAVDesc => get('settingsWebDAVDesc');
  String get settingsSyncNow => get('settingsSyncNow');
  String get settingsSyncNowDesc => get('settingsSyncNowDesc');
  String get settingsSecurity => get('settingsSecurity');
  String get settingsLockVault => get('settingsLockVault');
  String get settingsLockVaultDesc => get('settingsLockVaultDesc');
  String get settingsSecurityAudit => get('settingsSecurityAudit');
  String get settingsSecurityAuditDesc => get('settingsSecurityAuditDesc');
  String get settingsAbout => get('settingsAbout');
  String get settingsVersion => get('settingsVersion');
  String get settingsGitHub => get('settingsGitHub');
  String get tabVault => get('tabVault');
  String get tabSettings => get('tabSettings');
  String get tabAuth => get('tabAuth');
  String get tabPasskeys => get('tabPasskeys');

  // Onboarding
  String get onboardingPrev => get('onboardingPrev');
  String get onboardingDone => get('onboardingDone');
  String get onboardingQuickSetup => get('onboardingQuickSetup');
  String get onboardingQuickSetupDesc => get('onboardingQuickSetupDesc');
  String get onboardingQuickSetupHint => get('onboardingQuickSetupHint');
  String get onboardingSecurityTitle => get('onboardingSecurityTitle');
  String get onboardingMasterPassword => get('onboardingMasterPassword');
  String get onboardingBiometric => get('onboardingBiometric');
  String get onboardingRecovery => get('onboardingRecovery');
  String get onboardingAutofillTitle => get('onboardingAutofillTitle');
  String get onboardingAutofillDesc => get('onboardingAutofillDesc');
  String get onboardingAutofillToggle => get('onboardingAutofillToggle');
  String get onboardingAutofillOpenSettings => get('onboardingAutofillOpenSettings');
  String get onboardingThemeTitle => get('onboardingThemeTitle');
  String get onboardingThemeDesc => get('onboardingThemeDesc');
  String get onboardingNavBarTitle => get('onboardingNavBarTitle');
  String get onboardingNavBarDesc => get('onboardingNavBarDesc');
  String get onboardingNavPasswords => get('onboardingNavPasswords');
  String get onboardingNavAuthenticators => get('onboardingNavAuthenticators');
  String get onboardingNavCards => get('onboardingNavCards');
  String get onboardingNavPasskeys => get('onboardingNavPasskeys');
  String get onboardingImportTitle => get('onboardingImportTitle');
  String get onboardingImportDesc => get('onboardingImportDesc');
  String get onboardingListTitle => get('onboardingListTitle');
  String get onboardingListDesc => get('onboardingListDesc');
  String get onboardingListRecent => get('onboardingListRecent');
  String get onboardingCardTitle => get('onboardingCardTitle');
  String get onboardingCardDesc => get('onboardingCardDesc');
  String get onboardingCardUsername => get('onboardingCardUsername');
  String get onboardingCardWebsite => get('onboardingCardWebsite');
  String get onboardingCardLinkedAuth => get('onboardingCardLinkedAuth');
  String get onboardingCardHideOther => get('onboardingCardHideOther');
  String get onboardingAuthTitle => get('onboardingAuthTitle');
  String get onboardingAuthDesc => get('onboardingAuthDesc');
  String get onboardingAuthIssuer => get('onboardingAuthIssuer');
  String get onboardingAuthAccount => get('onboardingAuthAccount');
  String get onboardingAuthProgress => get('onboardingAuthProgress');
  String get onboardingAuthSmooth => get('onboardingAuthSmooth');
  String get onboardingComplete => get('onboardingComplete');
  String get onboardingCompleteDesc => get('onboardingCompleteDesc');
  String get onboardingLanguageSystem => get('onboardingLanguageSystem');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final lang = locale.languageCode;
    final strings = switch (lang) {
      'zh' => zhStrings,
      'ja' => jaStrings,
      _ => enStrings,
    };
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
