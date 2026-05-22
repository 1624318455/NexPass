import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../main.dart';
import '../state/unlock_state.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _usePassword = false;
  bool _bioAvailable = false;
  bool _checkingBio = true;
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometric());
  }

  Future<void> _initBiometric() async {
    final bioService = ref.read(biometricServiceProvider);
    final supported = await bioService.isDeviceSupported();
    final canCheck = await bioService.canCheckBiometrics();

    if (!mounted) return;

    _bioAvailable = supported && canCheck;
    _checkingBio = false;

    if (_bioAvailable) {
      // Auto-attempt biometric unlock
      _tryBiometric();
    } else {
      // No biometrics available — show password directly
      setState(() => _usePassword = true);
    }
  }

  Future<void> _tryBiometric() async {
    if (!_bioAvailable || !mounted) return;

    setState(() => _loading = true);

    final bioService = ref.read(biometricServiceProvider);
    final notifier = ref.read(unlockStateProvider.notifier);
    final success = await notifier.unlockWithBiometric(
      authenticate: (reason) => bioService.authenticate(reason: reason),
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (!success) {
      setState(() {
        _usePassword = true;
        _error = 'Biometric authentication failed. Please use your master password.';
      });
    }
  }

  Future<void> _unlockWithPassword() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your master password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final notifier = ref.read(unlockStateProvider.notifier);
    final success = await notifier.unlockWithPassword(password);

    if (!mounted) return;

    setState(() => _loading = false);

    if (!success) {
      setState(() => _error = 'Incorrect password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(32, 32, 32, MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NexIcon(NexIconType.shield, size: 64, color: cs.primary),
                const SizedBox(height: 24),
                Text(
                  'NexPass',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                // Status text
                if (_checkingBio)
                  Text('Checking biometric status...',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                else if (_usePassword)
                  Text(S.passwordLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                else
                  Text('Authenticate to unlock',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),

                const SizedBox(height: 40),

                // Loading indicator while checking biometrics
                if (_checkingBio) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Initializing...',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ]

                // Biometric button
                else if (!_usePassword) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _tryBiometric,
                      icon: _loading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                          : NexIcon(NexIconType.shield, size: 20, color: cs.onPrimary),
                      label: Text(_loading ? 'Authenticating...' : 'Use Biometrics',
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _usePassword = true),
                    child: const Text('Use Master Password'),
                  ),
                ]

                // Password input
                else ...[
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          NexIcon(NexIconType.shield, size: 16, color: cs.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onErrorContainer)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: S.passwordLabel,
                      prefixIcon: const NexIcon(NexIconType.lock, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(NexTheme.rSm)),
                    ),
                    onSubmitted: (_) => _unlockWithPassword(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _unlockWithPassword,
                      child: _loading
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                          : const Text('Unlock', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  if (_bioAvailable) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _usePassword = false;
                        _error = null;
                      }),
                      child: const Text('Use Biometrics'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }
}
