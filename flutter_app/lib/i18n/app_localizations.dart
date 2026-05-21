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
