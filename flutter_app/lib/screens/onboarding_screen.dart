import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import 'package:file_picker/file_picker.dart';
import '../services/autofill_engine.dart';
import '../services/csv_import_service.dart';
import '../services/sync_service.dart';
import '../state/sync_state.dart';
import '../theme/nex_theme.dart';
import 'import_preview_screen.dart';
import '../widgets/nex_icons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;
  static const _totalPages = 10;

  // ── Mutable settings being configured during onboarding ─────────────
  String _language = 'system';
  bool _biometricEnabled = false;
  bool _autofillEnabled = false;
  int _themeIndex = 0;
  bool _navPasswords = true;
  bool _navAuthenticators = true;
  bool _navCards = true;
  bool _navPasskeys = true;
  bool _showRecent = true;
  bool _showFavorites = true;
  bool _cardShowUsername = true;
  bool _cardShowWebsite = true;
  bool _cardShowAuth = false;
  bool _cardHideOther = false;
  bool _authShowIssuer = true;
  bool _authShowAccount = true;
  bool _authShowProgress = true;
  bool _authSmoothAnim = true;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _next() {
    if (_page < _totalPages - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _complete();
    }
  }

  void _prev() {
    if (_page > 0) {
      _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _skip() => _complete();

  void _complete() async {
    // Persist all onboarding settings
    final settingsNotifier = ref.read(appSettingsNotifierProvider.notifier);
    await settingsNotifier.update((s) {
      s.masterPasswordSet = true;
      s.biometricEnabled = _biometricEnabled;
      s.autofillEnabled = _autofillEnabled;
      s.themeColorIndex = _themeIndex;
      s.navPasswords = _navPasswords;
      s.navAuthenticators = _navAuthenticators;
      s.navCards = _navCards;
      s.navPasskeys = _navPasskeys;
      s.showRecentShortcuts = _showRecent;
      s.showFavorites = _showFavorites;
      s.cardShowUsername = _cardShowUsername;
      s.cardShowWebsite = _cardShowWebsite;
      s.cardShowLinkedAuth = _cardShowAuth;
      s.cardHideOtherWhenAuth = _cardHideOther;
      s.authShowIssuer = _authShowIssuer;
      s.authShowAccount = _authShowAccount;
      s.authShowProgressBar = _authShowProgress;
      s.authSmoothAnimation = _authSmoothAnim;
      s.language = _language;
    });

    // Persist onboarding completion
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write(key: 'onboarding_done', value: 'true');

    // Update in-memory state — MaterialApp.build() will rebuild and
    // switch home: from OnboardingScreen to MainScreen automatically.
    ref.read(onboardingDoneProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final S = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(S.onboardingSkip, style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _page1QuickSetup(S, cs),
                  _page2Security(S, cs),
                  _page3Autofill(S, cs),
                  _page4Theme(S, cs),
                  _page5NavBar(S, cs),
                  _page6Import(S, cs),
                  _page7ListAdjust(S, cs),
                  _page8CardAdjust(S, cs),
                  _page9AuthAdjust(S, cs),
                  _page10Complete(S, cs),
                ],
              ),
            ),

            // Bottom: indicators + navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  // Step indicator
                  ...List.generate(_totalPages, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 4),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? cs.primary : cs.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )),
                  const Spacer(),
                  // Prev button
                  if (_page > 0)
                    TextButton(
                      onPressed: _prev,
                      child: Text(S.onboardingPrev, style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                  // Next / Done button
                  FilledButton(
                    onPressed: _next,
                    child: Text(_page < _totalPages - 1 ? S.onboardingNext : S.onboardingDone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 1: Quick Setup
  // ════════════════════════════════════════════════════════════════════

  Widget _page1QuickSetup(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingQuickSetup, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(S.onboardingQuickSetupDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 32),

          // Language setting
          _settingTile(
            icon: NexIconType.language,
            title: S.settingsLanguage,
            trailing: Text(_langName(_language), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            onTap: () => _showLanguagePicker(cs),
          ),

          const SizedBox(height: 16),
          Text(S.onboardingQuickSetupHint, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 2: Security Settings
  // ════════════════════════════════════════════════════════════════════

  Widget _page2Security(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingSecurityTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 24),

          // Step 1: Master password (already set)
          _stepTile(1, S.onboardingMasterPassword, true, cs),
          const SizedBox(height: 12),

          // Step 2: Biometric
          _stepTile(2, S.onboardingBiometric, _biometricEnabled, cs,
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: (v) async {
                  if (v) {
                    // Turning ON: verify device supports biometrics
                    final bioService = ref.read(biometricServiceProvider);
                    final supported = await bioService.isDeviceSupported();
                    final canCheck = await bioService.canCheckBiometrics();
                    if (!supported || !canCheck) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This device does not support biometric authentication')),
                        );
                      }
                      return;
                    }
                    // Try authenticating to verify enrollment
                    final authenticated = await bioService.authenticate(reason: 'Verify biometric enrollment');
                    if (!authenticated) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometric verification failed')),
                        );
                      }
                      return;
                    }
                  }
                  setState(() => _biometricEnabled = v);
                },
              )),
          const SizedBox(height: 12),

          // Step 3: Recovery questions
          _stepTile(3, S.onboardingRecovery, false, cs),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 3: Autofill Settings
  // ════════════════════════════════════════════════════════════════════

  Widget _page3Autofill(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingAutofillTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingAutofillDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 32),

          _settingTile(
            icon: NexIconType.person,
            title: S.onboardingAutofillToggle,
            trailing: Switch(
              value: _autofillEnabled,
              onChanged: (v) => setState(() => _autofillEnabled = v),
            ),
          ),

          if (_autofillEnabled) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => AutofillEngine.openSystemSettings(),
              icon: const NexIcon(NexIconType.gear, size: 18),
              label: Text(S.onboardingAutofillOpenSettings),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 4: Theme Settings
  // ════════════════════════════════════════════════════════════════════

  Widget _page4Theme(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingThemeTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingThemeDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 32),

          // Color presets grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
            ),
            itemCount: NexTheme.themePresets.length,
            itemBuilder: (context, i) {
              final color = NexTheme.themePresets[i];
              final isSelected = i == _themeIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _themeIndex = i);
                  ref.read(appSettingsNotifierProvider.notifier).update((s) => s.themeColorIndex = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(height: 6),
                        Text(_themeName(i), style: TextStyle(fontSize: 11, color: cs.onSurface)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 5: Bottom Nav Settings
  // ════════════════════════════════════════════════════════════════════

  Widget _page5NavBar(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingNavBarTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingNavBarDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          _toggleTile(S.onboardingNavPasswords, _navPasswords, (v) {
            setState(() => _navPasswords = v);
            ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navPasswords = v);
          }),
          _toggleTile(S.onboardingNavAuthenticators, _navAuthenticators, (v) {
            setState(() => _navAuthenticators = v);
            ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navAuthenticators = v);
          }),
          _toggleTile(S.onboardingNavCards, _navCards, (v) {
            setState(() => _navCards = v);
            ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navCards = v);
          }),
          _toggleTile(S.onboardingNavPasskeys, _navPasskeys, (v) {
            setState(() => _navPasskeys = v);
            ref.read(appSettingsNotifierProvider.notifier).update((s) => s.navPasskeys = v);
          }),

          const SizedBox(height: 24),

          // Preview
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_navPasswords) _navPreviewItem(NexIconType.lock, S.tabVault, cs),
                if (_navAuthenticators) _navPreviewItem(NexIconType.clock, S.tabAuth, cs),
                if (_navCards) _navPreviewItem(NexIconType.globe, S.tabCards, cs),
                if (_navPasskeys) _navPreviewItem(NexIconType.key, S.tabPasskeys, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 6: Data Import
  // ════════════════════════════════════════════════════════════════════

  Widget _page6Import(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingImportTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingImportDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          _importOption(NexIconType.key, 'Bitwarden', 'Import from Bitwarden vault', cs,
              onTap: () => _pickAndImport('Bitwarden')),
          _importOption(NexIconType.cloud, 'WebDAV', 'Connect to WebDAV server', cs,
              onTap: () => _showWebDAVDialog()),
          _importOption(NexIconType.lock, 'KeePass', 'Import from KeePass database', cs,
              onTap: () => _pickAndImport('KeePass')),
          _importOption(NexIconType.stickyNote, 'CSV / File', 'Import from CSV or JSON file', cs,
              onTap: () => _pickAndImport('Generic CSV')),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 7: Password List Adjustments
  // ════════════════════════════════════════════════════════════════════

  Widget _page7ListAdjust(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingListTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingListDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          _toggleTile(S.onboardingListRecent, _showRecent, (v) => setState(() => _showRecent = v)),
          _toggleTile(S.settingsShowFavorites, _showFavorites, (v) => setState(() => _showFavorites = v)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 8: Password Card Adjustments
  // ════════════════════════════════════════════════════════════════════

  Widget _page8CardAdjust(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingCardTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingCardDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          _toggleTile(S.onboardingCardUsername, _cardShowUsername, (v) => setState(() => _cardShowUsername = v)),
          _toggleTile(S.onboardingCardWebsite, _cardShowWebsite, (v) => setState(() => _cardShowWebsite = v)),
          _toggleTile(S.onboardingCardLinkedAuth, _cardShowAuth, (v) => setState(() => _cardShowAuth = v)),
          _toggleTile(S.onboardingCardHideOther, _cardHideOther, (v) => setState(() => _cardHideOther = v)),

          const SizedBox(height: 16),

          // Card preview
          _cardPreview(cs),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 9: Authenticator Card Adjustments
  // ════════════════════════════════════════════════════════════════════

  Widget _page9AuthAdjust(S, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(S.onboardingAuthTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 12),
          Text(S.onboardingAuthDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 24),

          _toggleTile(S.onboardingAuthIssuer, _authShowIssuer, (v) => setState(() => _authShowIssuer = v)),
          _toggleTile(S.onboardingAuthAccount, _authShowAccount, (v) => setState(() => _authShowAccount = v)),
          _toggleTile(S.onboardingAuthProgress, _authShowProgress, (v) => setState(() => _authShowProgress = v)),
          _toggleTile(S.onboardingAuthSmooth, _authSmoothAnim, (v) => setState(() => _authSmoothAnim = v)),

          const SizedBox(height: 16),

          // TOTP preview
          _authPreview(cs),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Page 10: Complete
  // ════════════════════════════════════════════════════════════════════

  Widget _page10Complete(S, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: NexIcon(NexIconType.check, size: 36, color: cs.onPrimaryContainer)),
            ),
            const SizedBox(height: 24),
            Text(S.onboardingComplete, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: cs.onSurface)),
            const SizedBox(height: 12),
            Text(S.onboardingCompleteDesc, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Shared widgets
  // ════════════════════════════════════════════════════════════════════

  Widget _settingTile({required NexIconType icon, required String title, required Widget trailing, VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: NexIcon(icon, size: 20, color: cs.onSurfaceVariant),
      title: Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _stepTile(int step, String label, bool completed, ColorScheme cs, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: completed ? cs.primary : cs.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: completed ? cs.primary : cs.outline),
            ),
            child: Center(
              child: completed
                  ? const NexIcon(NexIconType.check, size: 14, color: Colors.white)
                  : Text('$step', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14))),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _toggleTile(String label, bool value, Function(bool) onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: cs.onSurface, fontSize: 14))),
            Switch(key: ValueKey('$label-$value'), value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _navPreviewItem(NexIconType icon, String label, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexIcon(icon, size: 20, color: cs.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _importOption(NexIconType icon, String title, String subtitle, ColorScheme cs, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            NexIcon(icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            NexIcon(NexIconType.chevronRight, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _cardPreview(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NexIcon(NexIconType.key, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Example Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          if (_cardShowUsername) ...[
            const SizedBox(height: 6),
            Text('user@example.com', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
          if (_cardShowWebsite) ...[
            const SizedBox(height: 4),
            Text('https://example.com', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
          if (_cardShowAuth) ...[
            const SizedBox(height: 4),
            Row(children: [
              NexIcon(NexIconType.clock, size: 12, color: cs.primary),
              const SizedBox(width: 4),
              Text('Authenticator linked', style: TextStyle(color: cs.primary, fontSize: 11)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _authPreview(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_authShowIssuer) ...[
            Text('Google', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 2),
          ],
          if (_authShowAccount) ...[
            Text('user@gmail.com', style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6006 1312', style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                if (_authShowProgress)
                  SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                      value: 0.5, strokeWidth: 2.5,
                      color: cs.primary,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(ColorScheme cs) {
    final S = AppLocalizations.of(context);
    final languages = [
      ('system', S.onboardingLanguageSystem, '\u{1F310}'),
      ('en', 'English', '\u{1F1EC}\u{1F1E7}'),
      ('zh', '中文', '\u{1F1E8}\u{1F1F3}'),
      ('ja', '日本語', '\u{1F1EF}\u{1F1F5}'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.settingsLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) {
            final selected = _language == l.$1;
            return ListTile(
              leading: Text(l.$3, style: const TextStyle(fontSize: 22)),
              title: Text(l.$2, style: TextStyle(color: selected ? cs.primary : cs.onSurface)),
              trailing: selected ? NexIcon(NexIconType.check, size: 18, color: cs.primary) : null,
              onTap: () {
                setState(() => _language = l.$1);
                ref.read(appSettingsNotifierProvider.notifier).update((s) => s.language = l.$1);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _pickAndImport(String formatName) async {
    final csvService = CsvImportService();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty || !context.mounted) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    try {
      final importResult = await csvService.importFromCsv(filePath);
      if (!context.mounted) return;

      if (importResult.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid credentials found in file')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImportPreviewScreen(
            items: importResult.items,
            formatName: importResult.format.name,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _showWebDAVDialog() async {
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
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  hintText: 'URL (https://dav.example.com/dav)',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexTheme.rSm)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                decoration: InputDecoration(
                  hintText: 'Username',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexTheme.rSm)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexTheme.rSm)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
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

  String _langName(String code) => switch (code) {
    'system' => 'System',
    'en' => 'English',
    'zh' => '中文',
    'ja' => '日本語',
    _ => 'System',
  };

  String _themeName(int index) => switch (index) {
    0 => 'Purple',
    1 => 'Blue',
    2 => 'Green',
    3 => 'Amber',
    4 => 'Red',
    5 => 'Violet',
    _ => '',
  };
}
