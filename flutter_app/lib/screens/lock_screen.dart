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
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-attempt biometric on first show.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final bioService = ref.read(biometricServiceProvider);
    final supported = await bioService.isDeviceSupported();
    if (!supported || !mounted) return;

    final notifier = ref.read(unlockStateProvider.notifier);
    final success = await notifier.unlockWithBiometric(
      authenticate: (reason) => bioService.authenticate(reason: reason),
    );
    if (!success && mounted) {
      setState(() => _usePassword = true);
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NexIcon(NexIconType.shield, size: 64, color: NexTheme.primary),
                const SizedBox(height: 24),
                Text(
                  'NexPass',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _usePassword ? S.passwordLabel : 'Authenticate to unlock',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),

                if (!_usePassword) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _tryBiometric,
                      icon: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const NexIcon(NexIconType.shield, size: 20, color: Colors.white),
                      label: Text('Use Biometrics', style: const TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexTheme.rMd)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _usePassword = true),
                    child: const Text('Use Master Password'),
                  ),
                ],

                if (_usePassword) ...[
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: S.passwordLabel,
                      prefixIcon: const NexIcon(NexIconType.lock, size: 20),
                      errorText: _error,
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
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Unlock', style: TextStyle(fontSize: 16)),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexTheme.rMd)),
                      ),
                    ),
                  ),
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
