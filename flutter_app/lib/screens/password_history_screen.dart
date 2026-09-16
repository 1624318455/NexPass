import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_localizations.dart';
import '../models/nex_item.dart';
import '../models/password_history.dart';
import '../services/password_history_service.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

/// 14-day password history (P1-6c).
///
/// Opening this screen prunes expired entries (via [PasswordHistoryService.list]).
/// Values stay masked — copy is the restore path (paste back into any field).
class PasswordHistoryScreen extends ConsumerStatefulWidget {
  const PasswordHistoryScreen({super.key});

  @override
  ConsumerState<PasswordHistoryScreen> createState() =>
      _PasswordHistoryScreenState();
}

class _PasswordHistoryScreenState
    extends ConsumerState<PasswordHistoryScreen> {
  List<PasswordHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final entries = await ref.read(passwordHistoryProvider).list(
            derivedKey: ref.read(masterKeyProvider),
          );
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      // Locked vault or missing provider — show empty.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _copy(PasswordHistoryEntry e) async {
    final value = e.decryptedValue;
    if (value == null || value.isEmpty) return;
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      final S = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.historyCopied(e.label))),
      );
    }
  }

  /// One-tap restore: writes the archived value back into its vault item.
  /// [VaultNotifier.updateItem] snapshots the new value as 'rotated', and the
  /// service dedups it against this entry, so no duplicate is created.
  /// Entries without an owning item (generated-but-never-saved) keep copy
  /// as their restore path.
  Future<void> _restore(PasswordHistoryEntry e) async {
    final value = e.decryptedValue;
    if (value == null || value.isEmpty || e.itemUuid == null) return;
    final S = AppLocalizations.of(context);
    final notifier = ref.read(vaultStateProvider.notifier);
    final items = await notifier.getAllItems();
    NexItem? target;
    try {
      target = items.firstWhere((i) => i.uuid == e.itemUuid);
    } catch (_) {
      target = null;
    }
    if (!mounted) return;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.historyRestoreMissing)),
      );
      return;
    }
    final idx = target.fields
        .indexWhere((f) => f.name == 'password' || f.fieldType == 2);
    if (idx == -1) return;
    HapticFeedback.mediumImpact();
    target.fields[idx].value = value;
    target.fields[idx].decryptedValue = value;
    target.updatedAt = DateTime.now();
    await notifier.updateItem(target);
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.historyRestored(e.label))),
      );
    }
  }

  Future<void> _delete(PasswordHistoryEntry e) async {
    await ref.read(passwordHistoryProvider).deleteEntry(e.id);
    await _reload();
  }

  Future<void> _clearAll() async {
    final S = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.historyClearTitle),
        content: Text(S.historyClearBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.historyClearAction)),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(passwordHistoryProvider).clearAll();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.historyTitle,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              onPressed: _clearAll,
              tooltip: S.historyClearAction,
              icon: const NexIcon(NexIconType.trash, size: 18),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _emptyState(context)
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        NexTheme.lg, NexTheme.sm, NexTheme.lg, 48),
                    itemCount: _entries.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: NexTheme.sm),
                    itemBuilder: (ctx, i) {
                      if (i == 0) return _retentionNote(context);
                      return _entryTile(context, _entries[i - 1]);
                    },
                  ),
                ),
    );
  }

  Widget _retentionNote(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final S = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(NexTheme.rSm),
      ),
      child: Row(
        children: [
          NexIcon(NexIconType.info, size: 14, color: cs.primary),
          const SizedBox(width: NexTheme.sm),
          Expanded(
            child: Text(
              S.historyRetentionNote,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(BuildContext context, PasswordHistoryEntry e) {
    final cs = Theme.of(context).colorScheme;
    final S = AppLocalizations.of(context);
    final length = e.decryptedValue?.length ?? 0;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: NexIcon(_iconFor(e.source), size: 20,
            color: cs.onSurfaceVariant),
        title: Text(e.label.isEmpty ? '(Untitled)' : e.label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_sourceLabel(e.source, S)} · ${_ageLabel(e.createdAt, S)} · $length chars · ••••••',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant, fontFamily: 'monospace'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (e.itemUuid != null)
              IconButton(
                onPressed: () => _restore(e),
                tooltip: S.historyRestore,
                icon: NexIcon(NexIconType.refresh,
                    size: 18, color: cs.tertiary),
              ),
            IconButton(
              onPressed: () => _copy(e),
              icon: NexIcon(NexIconType.copy, size: 18, color: cs.primary),
            ),
            IconButton(
              onPressed: () => _delete(e),
              icon: NexIcon(NexIconType.trash, size: 18, color: cs.error),
            ),
          ],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: NexTheme.lg, vertical: 2),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final S = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexIcon(NexIconType.clock, size: 48, color: cs.outline),
          const SizedBox(height: NexTheme.lg),
          Text(S.historyEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: NexTheme.sm),
          Text(S.historyEmptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  NexIconType _iconFor(String source) {
    switch (source) {
      case 'created':
        return NexIconType.plus;
      case 'rotated':
        return NexIconType.refresh;
      default:
        return NexIconType.key;
    }
  }

  String _sourceLabel(String source, AppLocalizations S) {
    switch (source) {
      case 'created':
        return S.historySourceCreated;
      case 'rotated':
        return S.historySourceRotated;
      default:
        return S.historySourceGenerated;
    }
  }

  String _ageLabel(DateTime at, AppLocalizations S) {
    final age = DateTime.now().difference(at);
    if (age.inMinutes < 1) return S.historyAgeJustNow;
    if (age.inHours < 1) return S.historyAgeMin(age.inMinutes);
    if (age.inDays < 1) return S.historyAgeHour(age.inHours);
    return S.historyAgeDay(age.inDays);
  }
}
