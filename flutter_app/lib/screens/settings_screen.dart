import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../state/sync_state.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';
import 'security_audit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: NexTheme.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, MediaQuery.of(context).padding.top + 12, 0, 80),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(NexTheme.lg, 0, NexTheme.lg, NexTheme.xl),
            child: Text(S.settings, style: const TextStyle(
              color: NexTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          _section(S.settingsGeneral),
          _tile(NexIconType.language, S.settingsLanguage, _langName(locale.languageCode),
              onTap: () => _showLanguageDialog(context, ref)),
          _section(S.settingsSync),
          _tile(NexIconType.cloud, S.settingsWebDAV, S.settingsWebDAVDesc,
              onTap: () => _showWebDAVDialog(context, ref)),
          _tile(NexIconType.refresh, S.settingsSyncNow, S.settingsSyncNowDesc,
              onTap: () {
                ref.read(syncStateProvider.notifier).syncNow();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sync started...')));
              }),
          _section(S.settingsSecurity),
          _tile(NexIconType.lock, S.settingsLockVault, S.settingsLockVaultDesc,
              onTap: () => ref.read(keyManagerProvider).wipe()),
          _tile(NexIconType.shield, S.settingsSecurityAudit, S.settingsSecurityAuditDesc,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecurityAuditScreen()))),
          _section(S.settingsAbout),
          _tile(NexIconType.info, S.settingsVersion, '1.0.0+1'),
          _tile(NexIconType.globe, S.settingsGitHub, 'github.com/1624318455/NexPass'),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.xl, NexTheme.lg, NexTheme.sm),
      child: Text(title, style: const TextStyle(
        color: NexTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  Widget _tile(NexIconType icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: NexIcon(icon, size: 20),
      title: Text(title, style: const TextStyle(color: NexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: NexTheme.textMuted, fontSize: 12)),
      trailing: const NexIcon(NexIconType.chevronRight, size: 16, color: NexTheme.textMuted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: NexTheme.lg, vertical: 2),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final languages = [
      ('en', 'English', '\u{1F1EC}\u{1F1E7}'),
      ('zh', '中文', '\u{1F1E8}\u{1F1F3}'),
      ('ja', '日本語', '\u{1F1EF}\u{1F1F5}'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) {
            final current = ref.read(localeProvider).languageCode == l.$1;
            return ListTile(
              leading: Text(l.$3, style: const TextStyle(fontSize: 22)),
              title: Text(l.$2, style: TextStyle(color: current ? NexTheme.primary : NexTheme.textPrimary)),
              trailing: current ? const NexIcon(NexIconType.check, size: 18, color: NexTheme.primary) : null,
              onTap: () {
                ref.read(localeProvider.notifier).state = Locale(l.$1);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _langName(String code) => switch (code) {
    'zh' => '中文', 'ja' => '日本語', _ => 'English',
  };

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
              const SizedBox(height: NexTheme.md),
              _fieldCtrl(userCtrl, 'Username'),
              const SizedBox(height: NexTheme.md),
              _fieldCtrl(passCtrl, 'Password', obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: NexTheme.textSecondary))),
          FilledButton(
            onPressed: () async {
              await secureStorage.write(key: 'webdav_url', value: urlCtrl.text);
              await secureStorage.write(key: 'webdav_user', value: userCtrl.text);
              await secureStorage.write(key: 'webdav_pass', value: passCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: NexTheme.primary),
            child: const Text('Save', style: TextStyle(color: NexTheme.background)),
          ),
        ],
      ),
    );
  }

  Widget _fieldCtrl(TextEditingController c, String hint, {bool obscure = false}) {
    return TextField(
      controller: c, obscureText: obscure,
      style: const TextStyle(color: NexTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: NexTheme.textMuted),
        filled: true, fillColor: NexTheme.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NexTheme.rSm),
            borderSide: const BorderSide(color: NexTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NexTheme.rSm),
            borderSide: const BorderSide(color: NexTheme.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
