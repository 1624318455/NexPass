import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n/app_localizations.dart';
import '../models/nex_item.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final NexItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late NexItem _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  NexIconType _iconForType(int type) {
    switch (type) {
      case 1: return NexIconType.person;
      case 2: return NexIconType.creditCard;
      case 3: return NexIconType.stickyNote;
      case 4: return NexIconType.clock;
      default: return NexIconType.key;
    }
  }

  Color _colorForType(BuildContext context, int type) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 1: return cs.primary;
      case 2: return cs.tertiary;
      case 3: return NexTheme.warning;
      case 4: return cs.error;
      default: return cs.primary;
    }
  }

  String _labelForType(int type) {
    switch (type) {
      case 1: return 'Login';
      case 2: return 'Card';
      case 3: return 'Secure Note';
      case 4: return 'Authenticator';
      default: return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final iconType = _iconForType(_item.type);
    final iconColor = _colorForType(context, _item.type);

    // Collect fields by category
    final username = _item.username;
    final passwordField = _item.fields.where((f) => f.name == 'password' || f.fieldType == 2).firstOrNull;
    final website = _item.website;
    final otherFields = _item.fields.where((f) =>
        f.name != 'username' && f.name != 'password' && f.name.toLowerCase() != 'website' &&
        f.name.toLowerCase() != 'url' && f.name != 'totpSecret' && f.fieldType != 2 && f.fieldType != 3
    ).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.sm, NexTheme.lg, 120),
            children: [
              // ── 1. Header info ───────────────────────
              _SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(NexTheme.rMd),
                      ),
                      child: Center(child: NexIcon(iconType, size: 22, color: iconColor)),
                    ),
                    const SizedBox(width: NexTheme.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_item.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_labelForType(_item.type), style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Account ──────────────────────────
              if (username.isNotEmpty)
                _FieldCard(
                  label: S.usernameLabel,
                  value: username,
                  onCopy: () => _copyValue(username),
                ),

              // ── 3. Password ─────────────────────────
              if (passwordField != null)
                _PasswordFieldCard(
                  field: passwordField,
                  onCopy: () => _copyValue(passwordField.decryptedValue ?? passwordField.value),
                ),

              // ── 4. Security status ──────────────────
              if (passwordField != null)
                _SecurityCard(password: passwordField.decryptedValue ?? passwordField.value),

              // ── 5. Website ──────────────────────────
              if (website.isNotEmpty)
                _WebsiteCard(url: website),

              // ── 9. TOTP ─────────────────────────────
              if (_item.hasTotp)
                _TotpCard(secret: _item.fields.firstWhere(
                  (f) => f.name == 'totpSecret' || f.fieldType == 3,
                  orElse: () => NexField(),
                ).decryptedValue ?? _item.totpSecret),

              // ── 6. Other fields (notes, custom) ─────
              for (final f in otherFields)
                _FieldCard(
                  label: f.name,
                  value: f.decryptedValue ?? f.value,
                  isSensitive: f.isSensitive,
                  onCopy: f.isSensitive ? () => _copyValue(f.decryptedValue ?? f.value) : null,
                ),

              // ── 7. Storage info ─────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Storage', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(height: NexTheme.sm),
                    _infoRow('vaultId', _item.vaultId ?? '-', cs),
                    const SizedBox(height: NexTheme.xs),
                    _infoRow('tags', _item.tags.isEmpty ? '-' : _item.tags.join(', '), cs),
                    const SizedBox(height: NexTheme.xs),
                    _infoRow('uuid', _item.uuid ?? '-', cs),
                  ],
                ),
              ),

              // ── 8. Timestamps ──────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.settingsShowRecent, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    const SizedBox(height: NexTheme.sm),
                    _infoRow('updatedAt', _formatDate(_item.updatedAt), cs),
                    const SizedBox(height: NexTheme.xs),
                    _infoRow('lastUsedAt', _item.lastUsedAt != null ? _formatDate(_item.lastUsedAt!) : '-', cs),
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom floating action bar ──────────────
          Positioned(
            left: NexTheme.lg, right: NexTheme.lg,
            bottom: MediaQuery.of(context).padding.bottom + NexTheme.lg,
            child: _BottomActionBar(
              isFavorite: _item.isFavorite,
              onToggleFavorite: _toggleFavorite,
              onExport: _showExportPlaceholder,
              onDelete: _confirmDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Future<void> _copyValue(String value) async {
    final S = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    ref.read(vaultStateProvider.notifier).markUsed(_item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.passwordCopied)),
    );
  }

  void _toggleFavorite() {
    ref.read(vaultStateProvider.notifier).toggleFavorite(_item);
    setState(() => _item.isFavorite = !_item.isFavorite);
  }

  void _showExportPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon')),
    );
  }

  void _confirmDelete() {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteTitle),
        content: Text(S.deleteConfirm(_item.name), style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(vaultStateProvider.notifier).deleteItem(_item);
              Navigator.pop(context);
            },
            child: Text(S.delete, style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Shared card wrapper ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: NexTheme.md),
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.lg),
        child: child,
      ),
    );
  }
}

// ── 2. Account field ────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isSensitive;
  final VoidCallback? onCopy;

  const _FieldCard({
    required this.label, required this.value,
    this.isSensitive = false, this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                const SizedBox(height: NexTheme.xs),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: NexIcon(NexIconType.copy, size: 18, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ── 3. Password field with visibility toggle ────────────────────────

class _PasswordFieldCard extends StatefulWidget {
  final NexField field;
  final VoidCallback onCopy;

  const _PasswordFieldCard({required this.field, required this.onCopy});

  @override
  State<_PasswordFieldCard> createState() => _PasswordFieldCardState();
}

class _PasswordFieldCardState extends State<_PasswordFieldCard> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plainValue = widget.field.decryptedValue ?? widget.field.value;
    final display = _obscured ? '•' * plainValue.length : plainValue;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('password', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: NexIcon(_obscured ? NexIconType.close : NexIconType.info, size: 18, color: cs.onSurfaceVariant),
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                onPressed: widget.onCopy,
                icon: NexIcon(NexIconType.copy, size: 18, color: cs.onSurfaceVariant),
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: NexTheme.xs),
          Text(display, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface, fontFamily: _obscured ? null : 'monospace')),
        ],
      ),
    );
  }
}

// ── 4. Security status card ─────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  final String password;
  const _SecurityCard({required this.password});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = _evaluateStrength(password);
    final label = score >= 4 ? 'Strong' : score >= 3 ? 'Good' : score >= 2 ? 'Fair' : 'Weak';
    final color = score >= 4 ? NexTheme.success : score >= 3 ? cs.tertiary : score >= 2 ? NexTheme.warning : cs.error;

    return _SectionCard(
      child: Row(
        children: [
          NexIcon(NexIconType.shield, size: 20, color: color),
          const SizedBox(width: NexTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: NexTheme.xs),
                LinearProgressIndicator(
                  value: score / 4,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: color,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _evaluateStrength(String pw) {
    int score = 0;
    if (pw.length >= 10) score++;
    if (pw.length >= 14) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(pw)) score++;
    return score.clamp(0, 4);
  }
}

// ── 5. Website card ────────────────────────────────────────────────

class _WebsiteCard extends StatelessWidget {
  final String url;
  const _WebsiteCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayUrl = url.startsWith('http') ? url : 'https://$url';

    return _SectionCard(
      child: Row(
        children: [
          NexIcon(NexIconType.globe, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: NexTheme.md),
          Expanded(
            child: Text(displayUrl, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.primary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse(displayUrl)),
            icon: NexIcon(NexIconType.chevronRight, size: 18, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── 9. TOTP card ───────────────────────────────────────────────────

class _TotpCard extends StatefulWidget {
  final String secret;
  const _TotpCard({required this.secret});

  @override
  State<_TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends State<_TotpCard> {
  String _code = '------';
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generate();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _generate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generate() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = 30 - (now % 30);
    final counter = now ~/ 30;

    // HMAC-SHA1 TOTP (RFC 6238)
    final key = _base32Decode(widget.secret);
    final counterBytes = ByteData(8)..setUint64(0, counter, Endian.big);
    // HMAC-SHA1 computed synchronously — fast enough for UI timer
    final digest = _hmacSha1(key, counterBytes.buffer.asUint8List());
    final offset = digest[digest.length - 1] & 0x0f;
    final code = ((digest[offset] & 0x7f) << 24 |
        (digest[offset + 1] & 0xff) << 16 |
        (digest[offset + 2] & 0xff) << 8 |
        (digest[offset + 3] & 0xff)) % 1000000;

    setState(() {
      _code = code.toString().padLeft(6, '0');
      _progress = remaining / 30;
    });
  }

  // Simple HMAC-SHA1 using dart:crypto approach (manual implementation)
  static List<int> _hmacSha1(List<int> key, List<int> data) {
    // Pad key to block size (64 bytes)
    final k = List<int>.filled(64, 0);
    for (var i = 0; i < key.length && i < 64; i++) k[i] = key[i];

    // Inner and outer pads
    final ipad = List<int>.generate(64, (i) => k[i] ^ 0x36);
    final opad = List<int>.generate(64, (i) => k[i] ^ 0x5c);

    // SHA-1 implementation
    int _rotl(int v, int n) => (v << n | (v >>> (32 - n))) & 0xFFFFFFFF;

    List<int> _sha1(List<int> msg) {
      var h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE, h3 = 0x10325476, h4 = 0xC3D2E1F0;

      // Pad message
      final padded = List<int>.from(msg);
      padded.add(0x80);
      while (padded.length % 64 != 56) padded.add(0);
      final len = msg.length * 8;
      padded.addAll([0, 0, 0, 0, (len >> 24) & 0xff, (len >> 16) & 0xff, (len >> 8) & 0xff, len & 0xff]);

      for (var chunk = 0; chunk < padded.length; chunk += 64) {
        final w = List<int>.filled(80, 0);
        for (var i = 0; i < 16; i++) {
          w[i] = (padded[chunk + i * 4] << 24) | (padded[chunk + i * 4 + 1] << 16) |
              (padded[chunk + i * 4 + 2] << 8) | padded[chunk + i * 4 + 3];
        }
        for (var i = 16; i < 80; i++) {
          w[i] = _rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
        }

        var a = h0, b = h1, c = h2, d = h3, e = h4;
        for (var i = 0; i < 80; i++) {
          int f, k;
          if (i < 20) { f = (b & c) | (~b & d); k = 0x5A827999; }
          else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1; }
          else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
          else { f = b ^ c ^ d; k = 0xCA62C1D6; }

          final temp = (_rotl(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
          e = d; d = c; c = _rotl(b, 30); b = a; a = temp;
        }
        h0 = (h0 + a) & 0xFFFFFFFF; h1 = (h1 + b) & 0xFFFFFFFF;
        h2 = (h2 + c) & 0xFFFFFFFF; h3 = (h3 + d) & 0xFFFFFFFF;
        h4 = (h4 + e) & 0xFFFFFFFF;
      }
      return [h0, h1, h2, h3, h4];
    }

    final innerHash = _sha1([...ipad, ...data]);
    final innerBytes = <int>[];
    for (final h in innerHash) {
      innerBytes.addAll([(h >> 24) & 0xff, (h >> 16) & 0xff, (h >> 8) & 0xff, h & 0xff]);
    }
    final outerHash = _sha1([...opad, ...innerBytes]);
    final result = <int>[];
    for (final h in outerHash) {
      result.addAll([(h >> 24) & 0xff, (h >> 16) & 0xff, (h >> 8) & 0xff, h & 0xff]);
    }
    return result;
  }

  static List<int> _base32Decode(String input) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final sanitized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    var bits = '';
    for (final c in sanitized.split('')) {
      final val = chars.indexOf(c);
      if (val >= 0) bits += val.toRadixString(2).padLeft(5, '0');
    }
    final result = <int>[];
    for (var i = 0; i + 8 <= bits.length; i += 8) {
      result.add(int.parse(bits.substring(i, i + 8), radix: 2));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUrgent = _progress < 0.2;

    return _SectionCard(
      child: Column(
        children: [
          Text('TOTP', style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: NexTheme.md),
          Text(
            '${_code.substring(0, 3)} ${_code.substring(3)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: isUrgent ? cs.error : cs.onSurface,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: NexTheme.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: cs.surfaceContainerHighest,
              color: isUrgent ? cs.error : cs.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: NexTheme.sm),
          Text(
            '${(30 - (_progress * 30).toInt())}s',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ── Bottom floating action bar ──────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _BottomActionBar({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(NexTheme.rXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: NexTheme.lg, vertical: NexTheme.sm),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(NexTheme.rXl),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BarIconButton(
                icon: NexIconType.heart,
                color: isFavorite ? cs.error : cs.onSurfaceVariant,
                onTap: onToggleFavorite,
              ),
              _BarIconButton(
                icon: NexIconType.pencil,
                color: cs.onSurfaceVariant,
                onTap: () {}, // Placeholder
              ),
              _BarIconButton(
                icon: NexIconType.download,
                color: cs.onSurfaceVariant,
                onTap: onExport,
              ),
              _BarIconButton(
                icon: NexIconType.trash,
                color: cs.error.withValues(alpha: 0.7),
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final NexIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _BarIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: NexIcon(icon, size: 22, color: color),
      ),
    );
  }
}
