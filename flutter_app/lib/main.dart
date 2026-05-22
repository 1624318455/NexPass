import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'i18n/app_localizations.dart';
import 'theme/nex_theme.dart';

import 'models/app_settings.dart';
import 'models/nex_item.dart';
import 'repositories/vault_repository.dart';
import 'services/biometric_service.dart';
import 'services/crypto_utils.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';
import 'state/sync_state.dart';
import 'state/unlock_state.dart';
import 'state/vault_state_notifier.dart';
import 'screens/lock_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final cryptoService = CryptoService();
  final secureStorage = SecureStorageService();
  final biometricService = BiometricService();

  // ── 1. Minimal init: open DB, load settings ──────────────────────────
  final onboardingDone = await secureStorage.read('onboarding_done') == 'true';
  final appSettings = await AppSettings.load(secureStorage);
  final isar = await DatabaseService.initialize();
  final repository = VaultRepository(isar: isar, cryptoService: cryptoService);

  // ── 2. Determine if biometric is enabled ─────────────────────────────
  final biometricEnabled = appSettings.biometricEnabled;

  // ── 3. Build sync service ────────────────────────────────────────────
  final webDavUrl = await secureStorage.read('webdav_url') ?? '';
  final webDavUser = await secureStorage.read('webdav_user') ?? '';
  final webDavPass = await secureStorage.read('webdav_pass') ?? '';
  final syncService = SyncService(
    webDavUrl: webDavUrl,
    username: webDavUser,
    password: webDavPass,
  );

  // ── 4. Launch app ────────────────────────────────────────────────────
  runApp(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(secureStorage),
        cryptoServiceProvider.overrideWithValue(cryptoService),
        biometricServiceProvider.overrideWithValue(biometricService),
        repositoryProvider.overrideWithValue(repository),
        onboardingDoneProvider.overrideWith((ref) => onboardingDone),
        appSettingsProvider.overrideWithValue(appSettings),
        syncServiceProvider.overrideWith((ref) => syncService),
        unlockStateProvider.overrideWith((ref) => UnlockNotifier(
              secureStorage: secureStorage,
              cryptoService: cryptoService,
              ref: ref,
            )),
      ],
      child: NexPassApp(biometricEnabled: biometricEnabled),
    ),
  );
}

// ---------------------------------------------------------------------------
// Demo data seeder (development only — all values are synthetic)
// ---------------------------------------------------------------------------

Future<void> _seedDemoDataIfEmpty(
  VaultRepository repository,
  Uint8List masterKey,
) async {
  final existing = await repository.searchItems(query: '', derivedKey: masterKey);
  if (existing.isNotEmpty) return;

  const uuid = Uuid();
  final items = <NexItem>[
    _item(uuid.v4(), 'Dev Account (Login)', 1, [
      _field('username', 'demo_user', 1, false),
      _field('password', 'D3m0!Str0ng#Pass_2026', 2, true),
    ]),
    _item(uuid.v4(), 'Virtual Card (Card)', 2, [
      _field('cardholder', 'DEMO USER', 1, false),
      _field('cardNumber', '4111 0000 0000 0001', 1, true),
      _field('cvv', '123', 4, true),
    ]),
    _item(uuid.v4(), 'MFA Account (TOTP)', 4, [
      _field('account', 'demo@mfa.example', 1, false),
      _field('password', 'T0tp!Demo#Key_2026', 2, true),
      _field('totpSecret', 'JBSWY3DPEHPK3PXP', 3, true),
    ]),
    _item(uuid.v4(), 'Weak Password Test', 1, [
      _field('username', 'audit_test', 1, false),
      _field('password', 'short', 2, true),
    ]),
  ];

  for (final item in items) {
    await repository.saveItem(item: item, derivedKey: masterKey);
  }
}

NexItem _item(String uuid, String name, int type, List<NexField> fields) {
  return NexItem()
    ..uuid = uuid
    ..name = name
    ..type = type
    ..fields = fields
    ..updatedAt = DateTime.now();
}

NexField _field(String name, String value, int fieldType, bool sensitive) {
  return NexField()
    ..name = name
    ..value = value
    ..fieldType = fieldType
    ..isSensitive = sensitive;
}

// ---------------------------------------------------------------------------
// App root widget
// ---------------------------------------------------------------------------

/// Locale provider — derives from AppSettings.language.
final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(appSettingsNotifierProvider);
  if (settings.language == 'system') {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }
  return Locale(settings.language);
});

/// Tracks whether the user has completed onboarding.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

/// SecureStorageService instance (injected at startup).
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError('Override at app startup');
});

/// CryptoService instance (injected at startup).
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  throw UnimplementedError('Override at app startup');
});

/// BiometricService instance (injected at startup).
final biometricServiceProvider = Provider<BiometricService>((ref) {
  throw UnimplementedError('Override at app startup');
});

/// KeyManager instance (injected at startup).
final keyManagerProvider = Provider<KeyManager>((ref) {
  throw UnimplementedError('Override at app startup');
});

/// AppSettings instance (injected at startup).
final appSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError('Override at app startup');
});

/// Notifier for mutable app settings.
final appSettingsNotifierProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(
    settings: ref.watch(appSettingsProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SecureStorageService _secureStorage;

  AppSettingsNotifier({required AppSettings settings, required SecureStorageService secureStorage})
      : _secureStorage = secureStorage,
        super(settings);

  Future<void> update(void Function(AppSettings) updater) async {
    updater(state);
    state = AppSettings.fromJson(state.toJson());
    await state.save(_secureStorage);
  }
}

class NexPassApp extends ConsumerStatefulWidget {
  final bool biometricEnabled;
  const NexPassApp({super.key, required this.biometricEnabled});

  @override
  ConsumerState<NexPassApp> createState() => _NexPassAppState();
}

class _NexPassAppState extends ConsumerState<NexPassApp> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final unlockNotifier = ref.read(unlockStateProvider.notifier);

    // Always derive & store the key first (needed for biometric recovery).
    await _ensureKeyStored();

    if (widget.biometricEnabled) {
      ref.read(appStateProvider.notifier).state = AppState.locked;
    } else {
      await _autoUnlock(unlockNotifier);
    }
  }

  /// Derive the master key from the password and store it in secure storage.
  /// This ensures biometric unlock can recover the key later.
  Future<void> _ensureKeyStored() async {
    final secureStorage = ref.read(secureStorageProvider);
    final cryptoService = ref.read(cryptoServiceProvider);

    // If key already stored, nothing to do.
    final existing = await secureStorage.recoverDerivedKey();
    if (existing != null) return;

    final salt = await secureStorage.getOrCreateMasterSalt(
      () => base64Encode(generateSalt()),
    );
    final saltBytes = base64Decode(salt);

    var masterPassword = const String.fromEnvironment(
      'NEXPASS_MASTER_PASSWORD',
      defaultValue: '',
    );
    if (masterPassword.isEmpty) {
      masterPassword = 'debug_master_key_2026';
    }

    final derivedKey = await cryptoService.deriveKey(
      password: masterPassword,
      salt: saltBytes,
    );

    await secureStorage.storeDerivedKey(derivedKey);
  }

  Future<void> _autoUnlock(UnlockNotifier notifier) async {
    // Try recovering stored key first.
    await notifier.tryAutoUnlock();
    final state = ref.read(unlockStateProvider);

    if (state.isUnlocked) {
      await _onUnlocked(state.derivedKey!);
      return;
    }

    // No stored key (first launch) — derive from debug password.
    final secureStorage = ref.read(secureStorageProvider);
    final cryptoService = ref.read(cryptoServiceProvider);

    final salt = await secureStorage.getOrCreateMasterSalt(
      () => base64Encode(generateSalt()),
    );
    final saltBytes = base64Decode(salt);

    var masterPassword = const String.fromEnvironment(
      'NEXPASS_MASTER_PASSWORD',
      defaultValue: '',
    );
    if (masterPassword.isEmpty) {
      masterPassword = 'debug_master_key_2026';
    }

    final derivedKey = await cryptoService.deriveKey(
      password: masterPassword,
      salt: saltBytes,
    );

    await secureStorage.storeDerivedKey(derivedKey);

    ref.read(unlockStateProvider.notifier).activateKey(derivedKey);

    await _onUnlocked(derivedKey);
  }

  Future<void> _onUnlocked(Uint8List derivedKey) async {
    // Seed demo data if needed.
    final repository = ref.read(repositoryProvider);
    await _seedDemoDataIfEmpty(repository, derivedKey);

    // Set up sync with derived key.
    final syncNotifier = ref.read(syncStateProvider.notifier);
    syncNotifier.updateDerivedKey(derivedKey);

    ref.read(appStateProvider.notifier).state = AppState.ready;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(appSettingsNotifierProvider);
    final seedColor = NexTheme.themePresets[settings.themeColorIndex];
    final appState = ref.watch(appStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        key: ValueKey('app-${settings.themeColorIndex}-${settings.language}'),
        title: 'NexPass',
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: NexTheme.lightThemeWith(seedColor),
        darkTheme: NexTheme.darkThemeWith(seedColor),
        themeMode: ThemeMode.system,
        home: switch (appState) {
          AppState.initializing => const Scaffold(body: Center(child: CircularProgressIndicator())),
          AppState.locked => const LockScreen(),
        AppState.ready => ref.watch(onboardingDoneProvider)
            ? const MainScreen()
            : const OnboardingScreen(),
        },
      ),
    );
  }
}
