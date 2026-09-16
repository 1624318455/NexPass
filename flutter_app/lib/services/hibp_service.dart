import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;

// ---------------------------------------------------------------------------
// HibpService — HaveIBeenPwned k-anonymity breach check (P1-7c, opt-in)
// ---------------------------------------------------------------------------

/// Checks a password against the HIBP Pwned Passwords corpus without ever
/// revealing it: only the first 5 hex chars of its SHA-1 reach the network
/// (k-anonymity range query). The suffix match happens locally.
///
/// Strictly opt-in (`AppSettings.hibpOptIn`, default off) — the vault stays
/// fully offline otherwise. All failures (offline, timeout, non-200) yield
/// `null` (unknown) instead of throwing, so callers can fall back to the
/// local compromised list in [SecurityAuditService].
class HibpService {
  static const String _rangeUrl = 'https://api.pwnedpasswords.com/range/';

  /// Request timeout — fail fast back to local-only auditing.
  static const Duration timeout = Duration(seconds: 10);

  final http.Client _client;

  HibpService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns the breach count for [password], 0 when not found, or `null`
  /// when the check could not be performed (opted out, offline, error).
  /// Empty passwords short-circuit to `null` without a network call.
  Future<int?> breachCount(String password) async {
    if (password.isEmpty) return null;
    final hex = await _sha1Hex(password);
    final prefix = hex.substring(0, 5);
    final suffix = hex.substring(5);
    try {
      final response = await _client
          .get(
            Uri.parse('$_rangeUrl$prefix'),
            // Padding flattens response size so it leaks nothing about the
            // queried prefix.
            headers: {'Add-Padding': 'true'},
          )
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      for (final line in const LineSplitter().convert(response.body)) {
        final parts = line.split(':');
        if (parts.length != 2) continue;
        if (parts[0].toUpperCase() == suffix) {
          return int.tryParse(parts[1].trim()) ?? 0;
        }
      }
      return 0;
    } catch (_) {
      return null;
    }
  }

  /// Uppercase SHA-1 hex, computed off the UI thread like other crypto ops.
  Future<String> _sha1Hex(String password) {
    return compute(_sha1HexSync, password);
  }

  static String _sha1HexSync(String password) {
    final digest = pc.SHA1Digest().process(utf8.encode(password));
    final buffer = StringBuffer();
    for (final byte in digest) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }
}

final hibpServiceProvider = Provider<HibpService>((ref) => HibpService());
