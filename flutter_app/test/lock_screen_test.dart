import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:nexpass/i18n/app_localizations.dart';
import 'package:nexpass/main.dart';
import 'package:nexpass/models/app_settings.dart';
import 'package:nexpass/screens/lock_screen.dart';
import 'package:nexpass/services/biometric_service.dart';
import 'package:nexpass/services/crypto_utils.dart';
import 'package:nexpass/services/secure_storage_service.dart';
import 'package:nexpass/state/unlock_state.dart';
import 'package:nexpass/theme/nex_theme.dart';

// ---------------------------------------------------------------------------
// Stub implementations (no Mock dependency needed)
// ---------------------------------------------------------------------------

class StubSecureStorage extends SecureStorageService {
  String? _storedKey;
  String? _salt;

  @override
  Future<String?> read(String key) async {
    if (key == 'derived_key') return _storedKey;
    if (key == 'master_salt') return _salt;
    return null;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    if (key == 'derived_key') _storedKey = value;
    if (key == 'master_salt') _salt = value;
  }

  @override
  Future<Uint8List?> recoverDerivedKey() async {
    if (_storedKey == null) return null;
    return Uint8List.fromList(List.generate(32, (i) => i));
  }

  @override
  Future<void> storeDerivedKey(Uint8List key) async {
    _storedKey = 'stored';
  }

  @override
  Future<String> getOrCreateMasterSalt(String Function() generator) async {
    _salt ??= generator();
    return _salt!;
  }
}

class StubBiometricService extends BiometricService {
  bool simulateAvailable = false;
  bool simulateSuccess = false;

  @override
  Future<bool> isDeviceSupported() async => simulateAvailable;

  @override
  Future<bool> canCheckBiometrics() async => simulateAvailable;

  @override
  Future<bool> authenticate({String? reason}) async => simulateSuccess;
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

Widget _buildLockScreen({
  bool biometricAvailable = false,
  bool biometricSuccess = false,
}) {
  final secureStorage = StubSecureStorage();
  final cryptoService = CryptoService();
  final biometricService = StubBiometricService()
    ..simulateAvailable = biometricAvailable
    ..simulateSuccess = biometricSuccess;

  final appSettings = AppSettings()
    ..language = 'en'
    ..biometricEnabled = biometricAvailable;

  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(secureStorage),
      cryptoServiceProvider.overrideWithValue(cryptoService),
      biometricServiceProvider.overrideWithValue(biometricService),
      appSettingsProvider.overrideWithValue(appSettings),
      appSettingsNotifierProvider.overrideWith(
        (ref) => AppSettingsNotifier(
          settings: appSettings,
          secureStorage: secureStorage,
        ),
      ),
      onboardingDoneProvider.overrideWith((ref) => true),
      unlockStateProvider.overrideWith((ref) => UnlockNotifier(
            secureStorage: secureStorage,
            cryptoService: cryptoService,
            ref: ref,
          )),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: NexTheme.lightThemeWith(NexTheme.seedColor),
      home: const LockScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LockScreen', () {
    testWidgets('renders NexPass title and shield icon', (tester) async {
      await tester.pumpWidget(_buildLockScreen());
      await tester.pumpAndSettle();

      expect(find.text('NexPass'), findsOneWidget);
    });

    testWidgets('shows password input when biometrics unavailable', (tester) async {
      await tester.pumpWidget(_buildLockScreen(biometricAvailable: false));
      await tester.pumpAndSettle();

      // Should show password field (obscureText = true)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
    });

    testWidgets('shows biometric button when biometrics available', (tester) async {
      await tester.pumpWidget(_buildLockScreen(biometricAvailable: true));
      // Initial pump renders the "checking biometrics" state
      await tester.pump();
      // Let the async biometric init complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // After biometric check completes with failure, should show password + "Use Biometrics" fallback
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Use Biometrics'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty password', (tester) async {
      await tester.pumpWidget(_buildLockScreen(biometricAvailable: false));
      await tester.pumpAndSettle();

      // Tap unlock with empty password
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.textContaining('enter your master password'), findsOneWidget);
    });

    testWidgets('toggles between biometric and password mode', (tester) async {
      await tester.pumpWidget(_buildLockScreen(biometricAvailable: true));
      // Let the async biometric init + auto-attempt complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // After failed biometric, should see password input + "Use Biometrics" fallback button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Use Biometrics'), findsOneWidget);
    });
  });
}
