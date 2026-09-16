import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  bool _usePassword = false;
  bool _bioAvailable = false;
  bool _checkingBio = true;
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // P0-3c-1: PIN keypad option (4-digit gate over keystore key)
  bool _usePin = false;
  bool _hasPin = false;
  String _pinEntry = '';

  // P0-3a: brand entrance + biometric pulse (core animation only, no deps)
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // P0-3b: failure shake (core animation + haptic, no deps)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeProgress;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _logoController.forward();
    _pulseController.repeat(reverse: true);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeProgress = CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometric());
  }

  void _triggerShake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  Future<void> _initBiometric() async {
    final bioService = ref.read(biometricServiceProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final supported = await bioService.isDeviceSupported();
    final canCheck = await bioService.canCheckBiometrics();
    final hasPin = await secureStorage.hasPin();

    if (!mounted) return;

    _bioAvailable = supported && canCheck;
    _checkingBio = false;
    _hasPin = hasPin;

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
      _triggerShake();
    }
  }

  Future<void> _unlockWithPassword() async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your master password');
      _triggerShake();
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
      _triggerShake();
    }
  }

  /// P0-3b: shake offset — damped sine, ±10px decaying to 0.
  double _shakeDx(double t) => sin(t * pi * 3) * 10 * (1 - t);

  // ── P0-3c-1: PIN keypad handlers ────────────────────────────────────

  void _onPinDigit(String d) {
    if (_loading || _pinEntry.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() => _pinEntry += d);
    if (_pinEntry.length == 4) _submitPin();
  }

  void _onPinBackspace() {
    if (_pinEntry.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pinEntry = _pinEntry.substring(0, _pinEntry.length - 1));
  }

  Future<void> _submitPin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final notifier = ref.read(unlockStateProvider.notifier);
    final success = await notifier.unlockWithPin(_pinEntry);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!success) {
      setState(() {
        _error = 'Incorrect PIN';
        _pinEntry = '';
      });
      _triggerShake();
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
                // P0-3a: shield scale-in entrance (Dashlane brand-motion parity)
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: NexIcon(NexIconType.shield, size: 64, color: cs.primary),
                  ),
                ),
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

                // Biometric button (with pulse affordance)
                else if (!_usePassword) ...[
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (context, child) => Transform.scale(
                      scale: _bioAvailable && !_loading ? _pulseScale.value : 1.0,
                      child: child,
                    ),
                    child: SizedBox(
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
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _usePassword = true),
                    child: const Text('Use Master Password'),
                  ),
                ]

                // Password input (P0-3b: whole block shakes on failure)
                else ...[
                  AnimatedBuilder(
                    animation: _shakeProgress,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeDx(_shakeProgress.value), 0),
                      child: child,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null) ...[
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              key: ValueKey(_error),
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
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: cs.onErrorContainer)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // P0-3c-1: Password / PIN switcher
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Password')),
                            ButtonSegment(value: true, label: Text('PIN')),
                          ],
                          selected: {_usePin},
                          onSelectionChanged: (s) => setState(() {
                            _usePin = s.first;
                            _error = null;
                            _pinEntry = '';
                          }),
                        ),
                        const SizedBox(height: 16),
                        if (_usePin)
                          _PinPad(
                            entry: _pinEntry,
                            hasPin: _hasPin,
                            loading: _loading,
                            onDigit: _onPinDigit,
                            onBackspace: _onPinBackspace,
                            onUsePassword: () => setState(() {
                              _usePin = false;
                              _error = null;
                            }),
                          )
                        else ...[
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: S.passwordLabel,
                              prefixIcon: const NexIcon(NexIconType.lock, size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(NexTheme.rSm)),
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
                        ],
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
                    ),
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
    _logoController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}

/// P0-3c-1: 4-dot display + numeric keypad (core widgets only).
///
/// Verify-only in this batch: if no PIN is set, shows a hint to unlock
/// with the master password first (setup lands in Settings, next batch).
class _PinPad extends StatelessWidget {
  final String entry;
  final bool hasPin;
  final bool loading;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onUsePassword;

  const _PinPad({
    required this.entry,
    required this.hasPin,
    required this.loading,
    required this.onDigit,
    required this.onBackspace,
    required this.onUsePassword,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!hasPin) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No PIN set yet',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton(onPressed: onUsePassword, child: const Text('Unlock with password first')),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < entry.length ? cs.primary : cs.surfaceContainerHighest,
                border: Border.all(color: cs.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (loading)
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              for (var d = 1; d <= 9; d++) _digitButton(context, '$d'),
              const SizedBox.shrink(),
              _digitButton(context, '0'),
              IconButton.filledTonal(
                onPressed: onBackspace,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
      ],
    );
  }

  Widget _digitButton(BuildContext context, String d) {
    return FilledButton.tonal(
      onPressed: () => onDigit(d),
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(d),
    );
  }
}
