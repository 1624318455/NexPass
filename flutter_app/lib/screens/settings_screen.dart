import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../models/app_settings.dart';
import '../repositories/vault_repository.dart';
import '../services/crypto_utils.dart';
import '../state/sync_state.dart';
import '../services/sync_service.dart';
import '../state/vault_state_notifier.dart';
import '../state/unlock_state.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';
import 'security_audit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(appSettingsNotifierProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 12, 0, 80),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(S.settings, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),

        _sectionHeader(S.settingsAppearance),
        _tile(context, NexIconType.language, S.settingsLanguage, _langName(locale.languageCode),
            onTap: () => _showLanguageDialog(context, ref)),
        _tile(context, NexIconType.gear, S.settingsTheme, _themeColorName(settings.themeColorIndex),
            trailing: _colorDot(NexTheme.themePresets[settings.themeColorIndex]),
            onTap: () => _showThemeDialog(context, ref, settings)),

        _sectionHeader(S.settingsSecurity),
        _tile(context, NexIconType.lock, S.settingsMasterPassword, S.settingsMasterPasswordDesc,
            onTap: () => _showChangePasswordDialog(context, ref)),
        _switchTile(context, NexIconType.shield, S.onboardingBiometric, S.settingsBiometricDesc,
            value: settings.biometricEnabled,
            onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.biometricEnabled = v)),

        _sectionHeader(S.settingsAutofillLabel),
        _switchTile(context, NexIconType.clipboard, S.onboardingAutofillToggle, S.settingsAutofillDesc,
            value: settings.autofillEnabled,
            onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.autofillEnabled = v)),

        _sectionHeader(S.settingsLayout),
        _tile(context, NexIconType.globe, S.settingsBottomNav, S.settingsBottomNavDesc,
            onTap: () => _showNavCustomizeDialog(context, ref, settings)),
        _tile(context, NexIconType.stickyNote, S.settingsPasswordList, S.settingsPasswordListDesc,
            onTap: () => _showListDisplayDialog(context, ref, settings)),
        _tile(context, NexIconType.key, S.settingsPasswordCards, S.settingsPasswordCardsDesc,
            onTap: () => _showCardDisplayDialog(context, ref, settings)),
        _tile(context, NexIconType.clock, S.settingsAuthDisplay, S.settingsAuthDisplayDesc,
            onTap: () => _showAuthDisplayDialog(context, ref, settings)),

        _sectionHeader(S.settingsDataManager),
        _tile(context, NexIconType.cloud, S.settingsWebDAV, S.settingsWebDAVDesc,
            onTap: () => _showWebDAVDialog(context, ref)),
        _tile(context, NexIconType.refresh, S.settingsSyncNow, S.settingsSyncNowDesc,
            onTap: () {
              ref.read(syncStateProvider.notifier).syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.settingsSyncNowDesc)));
            }),
        _tile(context, NexIconType.plus, S.settingsImport, S.settingsImportDesc,
            onTap: () => _showImportDialog(context, ref)),

        _tile(context, NexIconType.shield, S.settingsSecurityAudit, S.settingsSecurityAuditDesc,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SecurityAuditScreen()))),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: FilledButton.icon(
            onPressed: () => _confirmLock(context, ref),
            icon: const NexIcon(NexIconType.lock, size: 18, color: Colors.white),
            label: Text(S.settingsLockVault, style: const TextStyle(color: Colors.white)),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexTheme.rMd)),
            ),
          ),
        ),

        _sectionHeader(S.settingsAbout),
        _tile(context, NexIconType.info, S.settingsVersion, '1.0.0+1'),
        _tile(context, NexIconType.globe, S.settingsGitHub, 'github.com/1624318455/NexPass', onTap: () {}),

        const SizedBox(height: 40),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(title, style: const TextStyle(
          color: NexTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  // ── Standard tile with chevron ────────────────────────────────────────

  Widget _tile(BuildContext context, NexIconType icon, String title, String subtitle,
      {VoidCallback? onTap, Widget? trailing}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: NexIcon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing ?? const NexIcon(NexIconType.chevronRight, size: 16, color: NexTheme.textMuted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  // ── Switch tile ───────────────────────────────────────────────────────

  Widget _switchTile(BuildContext context, NexIconType icon, String title, String subtitle,
      {required bool value, required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: NexIcon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  // ── Language name helper ──────────────────────────────────────────────

  String _langName(String code) => switch (code) {
    'zh' => '中文', 'ja' => '日本語', _ => 'English',
  };

  // ── Theme color name ──────────────────────────────────────────────────

  String _themeColorName(int index) => switch (index) {
    0 => 'Purple', 1 => 'Blue', 2 => 'Green',
    3 => 'Amber', 4 => 'Red', 5 => 'Violet',
    _ => 'Purple',
  };

  // ── Color dot indicator ───────────────────────────────────────────────

  Widget _colorDot(Color color) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: NexTheme.border, width: 2),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final languages = [
      ('system', 'Follow System'),
      ('en', 'English'),
      ('zh', '中文'),
      ('ja', '日本語'),
    ];
    final currentLang = ref.read(appSettingsNotifierProvider).language;
    final currentLocale = ref.read(localeProvider).languageCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) {
            final isSelected = l.$1 == 'system'
                ? currentLang == 'system'
                : (currentLang == 'system' ? currentLocale == l.$1 : currentLang == l.$1);
            return ListTile(
              title: Text(l.$2),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary) : null,
              onTap: () {
                final code = l.$1;
                if (code == 'system') {
                  ref.read(appSettingsNotifierProvider.notifier).update((s) => s.language = 'system');
                  ref.read(localeProvider.notifier).state = WidgetsBinding.instance.platformDispatcher.locale;
                } else {
                  ref.read(appSettingsNotifierProvider.notifier).update((s) => s.language = code);
                  ref.read(localeProvider.notifier).state = Locale(code);
                }
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final names = ['Purple', 'Blue', 'Green', 'Amber', 'Red', 'Violet'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme Color'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
            ),
            itemCount: NexTheme.themePresets.length,
            itemBuilder: (ctx, i) {
              final isSelected = settings.themeColorIndex == i;
              final color = NexTheme.themePresets[i];
              return GestureDetector(
                onTap: () {
                  ref.read(appSettingsNotifierProvider.notifier).update((s) => s.themeColorIndex = i);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(names[i], style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Master Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fieldCtrl(currentCtrl, 'Current password', obscure: true),
                const SizedBox(height: 12),
                _fieldCtrl(newCtrl, 'New password', obscure: true),
                const SizedBox(height: 12),
                _fieldCtrl(confirmCtrl, 'Confirm new password', obscure: true),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading ? null : () async {
                // Validate
                if (currentCtrl.text.isEmpty) {
                  setDialogState(() => error = 'Current password is required');
                  return;
                }
                if (newCtrl.text.length < 8) {
                  setDialogState(() => error = 'New password must be at least 8 characters');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setDialogState(() => error = 'Passwords do not match');
                  return;
                }
                if (newCtrl.text == currentCtrl.text) {
                  setDialogState(() => error = 'New password must differ from current');
                  return;
                }

                setDialogState(() { loading = true; error = null; });

                try {
                  final secureStorage = ref.read(secureStorageProvider);
                  final cryptoService = ref.read(cryptoServiceProvider);
                  final repository = ref.read(repositoryProvider);
                  final unlockNotifier = ref.read(unlockStateProvider.notifier);
                  final currentKey = ref.read(unlockStateProvider).derivedKey;

                  // Derive key from current password
                  final salt = await secureStorage.getOrCreateMasterSalt(
                    () => base64Encode(generateSalt()),
                  );
                  final saltBytes = base64Decode(salt);
                  final currentDerivedKey = await cryptoService.deriveKey(
                    password: currentCtrl.text,
                    salt: saltBytes,
                  );

                  // Verify current password
                  if (currentKey != null && !_bytesEqual(currentDerivedKey, currentKey)) {
                    setDialogState(() { loading = false; error = 'Current password is incorrect'; });
                    return;
                  }

                  // Derive new key
                  final newDerivedKey = await cryptoService.deriveKey(
                    password: newCtrl.text,
                    salt: saltBytes,
                  );

                  // Re-encrypt all items
                  await repository.reEncryptAllItems(
                    oldKey: currentDerivedKey,
                    newKey: newDerivedKey,
                  );

                  // Store new key
                  await secureStorage.storeDerivedKey(newDerivedKey);

                  // Activate KeyManager with new key
                  final km = KeyManager(
                    sessionTimeout: const Duration(minutes: 5),
                    onLock: () {
                      if (context.mounted) {
                        ref.read(appStateProvider.notifier).state = AppState.locked;
                      }
                    },
                  );
                  km.activate(newDerivedKey);

                  // Update unlock state
                  unlockNotifier.state = UnlockState(
                    derivedKey: newDerivedKey,
                    keyManager: km,
                    isUnlocked: true,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password changed successfully')));
                  }
                } catch (e) {
                  setDialogState(() { loading = false; error = 'Error: $e'; });
                }
              },
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showNavCustomizeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsBottomNav),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(S.onboardingNavPasswords),
              value: settings.navPasswords,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navPasswords = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(S.onboardingNavAuthenticators),
              value: settings.navAuthenticators,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navAuthenticators = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(S.onboardingNavCards),
              value: settings.navCards,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navCards = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(S.onboardingNavPasskeys),
              value: settings.navPasskeys,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navPasskeys = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showListDisplayDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsPasswordList),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(S.settingsShowRecent),
              value: settings.showRecentShortcuts,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.showRecentShortcuts = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(S.settingsShowFavorites),
              value: settings.showFavorites,
              onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.showFavorites = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showCardDisplayDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsPasswordCards),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(S.onboardingCardUsername),
                value: settings.cardShowUsername,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.cardShowUsername = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingCardWebsite),
                value: settings.cardShowWebsite,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.cardShowWebsite = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingCardLinkedAuth),
                value: settings.cardShowLinkedAuth,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.cardShowLinkedAuth = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingCardHideOther),
                value: settings.cardHideOtherWhenAuth,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.cardHideOtherWhenAuth = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showAuthDisplayDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsAuthDisplay),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(S.onboardingAuthIssuer),
                value: settings.authShowIssuer,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.authShowIssuer = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingAuthAccount),
                value: settings.authShowAccount,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.authShowAccount = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingAuthProgress),
                value: settings.authShowProgressBar,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.authShowProgressBar = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: Text(S.onboardingAuthSmooth),
                value: settings.authSmoothAnimation,
                onChanged: (v) => ref.read(appSettingsNotifierProvider.notifier).update((s) => s.authSmoothAnimation = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsImport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const NexIcon(NexIconType.key, size: 20),
              title: Text(S.settingsBitwarden),
              onTap: () { Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const NexIcon(NexIconType.lock, size: 20),
              title: Text(S.settingsKeePass),
              onTap: () { Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const NexIcon(NexIconType.stickyNote, size: 20),
              title: Text(S.settingsCSV),
              onTap: () { Navigator.pop(ctx); },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showWebDAVDialog(BuildContext context, WidgetRef ref) async {
    final secureStorage = ref.read(secureStorageProvider);
    final urlCtrl = TextEditingController(text: await secureStorage.read('webdav_url') ?? '');
    final userCtrl = TextEditingController(text: await secureStorage.read('webdav_user') ?? '');
    final passCtrl = TextEditingController(text: await secureStorage.read('webdav_pass') ?? '');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WebDAV Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _fieldCtrl(urlCtrl, 'URL (https://dav.example.com/dav)'),
              const SizedBox(height: 12),
              _fieldCtrl(userCtrl, 'Username'),
              const SizedBox(height: 12),
              _fieldCtrl(passCtrl, 'Password', obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await secureStorage.write(key: 'webdav_url', value: urlCtrl.text);
              await secureStorage.write(key: 'webdav_user', value: userCtrl.text);
              await secureStorage.write(key: 'webdav_pass', value: passCtrl.text);

              // Rebuild SyncService with new credentials
              final newSyncService = SyncService(
                webDavUrl: urlCtrl.text,
                username: userCtrl.text,
                password: passCtrl.text,
              );
              ref.read(syncServiceProvider.notifier).state = newSyncService;

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLock(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsLockVault),
        content: Text(S.settingsLockVaultDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel)),
          FilledButton(
            onPressed: () {
              ref.read(unlockStateProvider.notifier).lock();
              ref.read(appStateProvider.notifier).state = AppState.locked;
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(S.settingsLockVault),
          ),
        ],
      ),
    );
  }

  Widget _fieldCtrl(TextEditingController c, String hint, {bool obscure = false}) {
    return TextField(
      controller: c, obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexTheme.rSm)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
