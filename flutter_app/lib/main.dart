import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'i18n/app_localizations.dart';
import 'theme/nex_theme.dart';

import 'models/nex_item.dart';
import 'repositories/vault_repository.dart';
import 'services/crypto_utils.dart';
import 'services/database_service.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';
import 'state/sync_state.dart';
import 'state/vault_state_notifier.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/security_audit_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cryptoService = CryptoService();
  final secureStorage = SecureStorageService();

  // ── 1. Attempt to recover a previously persisted derived key ──────────
  Uint8List? derivedKey = await secureStorage.recoverDerivedKey();

  if (derivedKey == null) {
    // ── 2. First launch or integrity check failed — derive fresh ────────
    final salt = await secureStorage.getOrCreateMasterSalt(
      () => base64Encode(generateSalt()),
    );
    final saltBytes = base64Decode(salt);

    // NOTE: In production, [masterPassword] MUST come from a user-facing
    // unlock screen. The value below is a development placeholder only
    // and MUST NOT be shipped to production.
    var masterPassword = const String.fromEnvironment(
      'NEXPASS_MASTER_PASSWORD',
      defaultValue: '',
    );
    if (masterPassword.isEmpty) {
      // DEBUG-ONLY fallback for first launch without env var.
      // Remove this block before production release.
      masterPassword = 'debug_master_key_2026';
    }

    derivedKey = await cryptoService.deriveKey(
      password: masterPassword,
      salt: saltBytes,
    );
  }

  // ── 3. Open Isar database ────────────────────────────────────────────
  final isar = await DatabaseService.initialize();

  // ── 4. Build repository & seed demo data ─────────────────────────────
  final repository = VaultRepository(
    isar: isar,
    cryptoService: cryptoService,
  );

  await _seedDemoDataIfEmpty(repository, derivedKey);

  // ── 5. Build sync service ──────────────────────────────────────────
  // NOTE: In production, WebDAV credentials must come from a settings
  // screen backed by SecureStorage. The values below are placeholders.
  final syncService = SyncService(
    webDavUrl: const String.fromEnvironment(
      'NEXPASS_WEBDAV_URL',
      defaultValue: '',
    ),
    username: const String.fromEnvironment(
      'NEXPASS_WEBDAV_USER',
      defaultValue: '',
    ),
    password: const String.fromEnvironment(
      'NEXPASS_WEBDAV_PASS',
      defaultValue: '',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        masterKeyProvider.overrideWithValue(derivedKey),
        repositoryProvider.overrideWithValue(repository),
        syncServiceProvider.overrideWithValue(syncService),
        syncStateProvider.overrideWith((ref) => SyncNotifier(
              syncService: ref.watch(syncServiceProvider),
              repository: ref.watch(repositoryProvider),
              derivedKey: ref.watch(masterKeyProvider),
            )),
      ],
      child: const NexPassApp(),
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

/// Locale provider — controls the app language.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Tracks whether the user has completed onboarding.
final onboardingDoneProvider = StateProvider<bool>((ref) => false);

class NexPassApp extends ConsumerWidget {
  const NexPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
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
      theme: NexTheme.theme,
      home: ref.watch(onboardingDoneProvider) ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
