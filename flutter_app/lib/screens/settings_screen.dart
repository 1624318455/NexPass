import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Text(S.settings, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        children: [
          // ── General ──
          _sectionHeader(S.settingsGeneral),
          _settingTile(
            emoji: '\u{1F310}',
            title: S.settingsLanguage,
            subtitle: _langName(currentLocale.languageCode),
            onTap: () => _showLanguageDialog(context, ref),
          ),

          const SizedBox(height: 16),

          // ── Sync ──
          _sectionHeader(S.settingsSync),
          _settingTile(
            emoji: '\u{2601}\u{FE0F}',
            title: S.settingsWebDAV,
            subtitle: S.settingsWebDAVDesc,
            onTap: () {},
          ),
          _settingTile(
            emoji: '\u{1F504}',
            title: S.settingsSyncNow,
            subtitle: S.settingsSyncNowDesc,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // ── Security ──
          _sectionHeader(S.settingsSecurity),
          _settingTile(
            emoji: '\u{1F512}',
            title: S.settingsLockVault,
            subtitle: S.settingsLockVaultDesc,
            onTap: () {},
          ),
          _settingTile(
            emoji: '\u{1F6E1}',
            title: S.settingsSecurityAudit,
            subtitle: S.settingsSecurityAuditDesc,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // ── About ──
          _sectionHeader(S.settingsAbout),
          _settingTile(
            emoji: '\u{2139}\u{FE0F}',
            title: S.settingsVersion,
            subtitle: '1.0.0+1',
            onTap: () {},
          ),
          _settingTile(
            emoji: '\u{1F517}',
            title: S.settingsGitHub,
            subtitle: 'github.com/1624318455/NexPass',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: const TextStyle(
        color: Color(0xFF8B949E), fontSize: 11, fontWeight: FontWeight.w700,
        letterSpacing: 0.8)),
    );
  }

  Widget _settingTile({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
      trailing: const Text('\u{203A}', style: TextStyle(color: Color(0xFF484F58), fontSize: 20)),
      onTap: onTap,
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
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) {
            final current = ref.read(localeProvider).languageCode == l.$1;
            return ListTile(
              leading: Text(l.$3, style: const TextStyle(fontSize: 24)),
              title: Text(l.$2, style: TextStyle(color: current ? const Color(0xFF2DD4BF) : Colors.white)),
              trailing: current ? const Text('\u{2714}', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 18)) : null,
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
    'zh' => '中文',
    'ja' => '日本語',
    _ => 'English',
  };
}
