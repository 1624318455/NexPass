import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../models/nex_item.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';
import 'clipboard_overlay.dart';
import 'item_detail_screen.dart';
import 'security_audit_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _searchController = TextEditingController();
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    return Stack(
      children: [
        Scaffold(
          body: _navIndex == 0
              ? _VaultPage(searchController: _searchController)
              : const SettingsScreen(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            height: 64,
            destinations: [
              NavigationDestination(icon: NexIcon(NexIconType.lock, size: 22), label: S.tabVault),
              NavigationDestination(icon: NexIcon(NexIconType.gear, size: 22), label: S.tabSettings),
            ],
          ),
          floatingActionButton: _navIndex == 0
              ? FloatingActionButton(
                  heroTag: 'vault-add-fab',
                  onPressed: () => _showAddSheet(context),
                  child: const NexIcon(NexIconType.plus, size: 24),
                )
              : null,
        ),
        const DualClipboardOverlay(),
      ],
    );
  }

  // P0-5: FAB morphs into a bottom sheet (was AlertDialog) with a shared
  // Hero transition on the sheet handle for perceived continuity.
  void _showAddSheet(BuildContext context) {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final nameC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();
    int type = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                NexTheme.lg, NexTheme.sm, NexTheme.lg, NexTheme.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shared Hero with the FAB for morph perception.
                const Hero(
                  tag: 'vault-add-fab',
                  child: SizedBox.shrink(),
                ),
                Text(S.addCredential,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: NexTheme.lg),
                _addField(nameC, S.nameLabel),
                const SizedBox(height: NexTheme.md),
                _addField(userC, S.usernameLabel),
                const SizedBox(height: NexTheme.md),
                _addField(passC, S.passwordLabel),
                const SizedBox(height: NexTheme.lg),
                Row(children: [
                  _typeBtn(S.typeLogin, 1, type,
                      (v) => setModalState(() => type = v)),
                  const SizedBox(width: NexTheme.sm),
                  _typeBtn(S.typeCard, 2, type,
                      (v) => setModalState(() => type = v)),
                  const SizedBox(width: NexTheme.sm),
                  _typeBtn(S.typeNote, 3, type,
                      (v) => setModalState(() => type = v)),
                ]),
                const SizedBox(height: NexTheme.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(S.cancel,
                            style: TextStyle(
                                color: cs.onSurfaceVariant))),
                    const SizedBox(width: NexTheme.sm),
                    FilledButton(
                      onPressed: () {
                        if (nameC.text.isNotEmpty &&
                            passC.text.isNotEmpty) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(vaultStateProvider.notifier)
                              .addNewCredential(
                                title: nameC.text,
                                itemType: type,
                                username: userC.text,
                                password: passC.text,
                              );
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(S.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _typeBtn(String label, int value, int current, Function(int) onSelect) {
    final isActive = value == current;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(NexTheme.rSm),
          border: Border.all(color: isActive ? cs.primary : cs.outline),
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? cs.primary : cs.onSurfaceVariant)),
      ),
    );
  }
}

// ── Vault page ────────────────────────────────────────────────────────

class _VaultPage extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  const _VaultPage({required this.searchController});

  @override
  ConsumerState<_VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<_VaultPage> {
  // ── P1-10: local multi-selection (uuid-keyed, page-scoped) ─────────────
  // Kept out of VaultState on purpose: selection is transient UI state and
  // must not leak into audit/sync or survive a vault reload.
  final Set<String> _selected = {};

  // ── P1-10 (B7): single-level folder filter, page-scoped like selection ──
  String? _folderFilter;

  String _keyOf(NexItem item) => item.uuid ?? 'id-${item.id}';
  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelect(NexItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      final k = _keyOf(item);
      if (_selected.contains(k)) {
        _selected.remove(k);
      } else {
        _selected.add(k);
      }
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultStateProvider);
    final vaultNotifier = ref.read(vaultStateProvider.notifier);
    final S = AppLocalizations.of(context);

    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(NexTheme.lg, MediaQuery.of(context).viewPadding.top + NexTheme.lg, NexTheme.lg, NexTheme.lg),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: NexIcon(NexIconType.shield, size: 18, color: cs.onPrimary)),
                ),
                const SizedBox(width: NexTheme.sm),
                Text(S.appTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityAuditScreen())),
                  child: NexIcon(NexIconType.shield, size: 20, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),

        // ── Search (Hero-shared for perceived continuity) ─────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                NexTheme.lg, NexTheme.lg, NexTheme.lg, NexTheme.sm),
            child: Hero(
              tag: 'vault-search',
              // TextField can't be Hero-flighted directly; wrap the
              // decoration container so the flight is a simple fade/size morph.
              child: Material(
                color: Colors.transparent,
                child: TextField(
                  key: const ValueKey('vault-search-field'),
                  controller: widget.searchController,
                  onChanged: vaultNotifier.setSearchQuery,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: S.searchHint,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: NexIcon(NexIconType.search,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, minHeight: 0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Tabs ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NexTheme.lg, vertical: NexTheme.xs),
            child: _buildTabs(ref, S, vaultState),
          ),
        ),

        // ── P1-10: batch action bar (selection mode only) ───────────────
        if (_selecting)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  NexTheme.lg, NexTheme.xs, NexTheme.lg, NexTheme.sm),
              child: _batchBar(S, vaultState),
            ),
          ),

        // ── P1-10 (B7): folder filter chips (single level) ──────────────
        SliverToBoxAdapter(
          child: _folderChips(S, vaultState),
        ),

        // ── Items ───────────────────────────────────────
        // P0-1: skeleton shimmer while loading, illustrated error state
        // with retry, illustrated empty state (1Password/Dashlane parity).
        if (vaultState.isLoading)
          const _VaultSkeletonSliver()
        else if (vaultState.errorMessage != null)
          SliverFillRemaining(
            child: _errorState(
              S,
              vaultState.errorMessage!,
              onRetry: vaultNotifier.loadVault,
            ),
          )
        else if (vaultState.items.isEmpty)
          SliverFillRemaining(child: _emptyState(S))
        else
          _itemSliverList(vaultState, S),
      ],
    );
  }

  Widget _tabChip(WidgetRef ref, String label, int index, int activeIndex) {
    final isActive = index == activeIndex;
    final cs = Theme.of(ref.context).colorScheme;
    return FilterChip(
      label: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      )),
      selected: isActive,
      onSelected: (_) => ref.read(vaultStateProvider.notifier).setTab(index),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
      side: BorderSide(color: isActive ? cs.primary : cs.outline),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _emptyState(S) {
    final cs = Theme.of(context).colorScheme;
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      // P0-1: illustrated empty state — branded shield medallion.
      Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Center(
            child:
                NexIcon(NexIconType.shield, size: 44, color: cs.primary)),
      ),
      const SizedBox(height: NexTheme.xl),
      Text(S.vaultEmpty,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.onSurface, fontWeight: FontWeight.w700)),
      const SizedBox(height: NexTheme.sm),
      Text(S.vaultEmptyHint,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant)),
    ]));
  }

  Widget _errorState(S, String message, {required VoidCallback onRetry}) {
    final cs = Theme.of(context).colorScheme;
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(NexTheme.xxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: NexIcon(NexIconType.shield, size: 44,
                  color: cs.onErrorContainer)),
        ),
        const SizedBox(height: NexTheme.xl),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant)),
        const SizedBox(height: NexTheme.lg),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ));
  }

  Widget _itemSliverList(VaultState state, S) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final matchesTab = (NexItem item) {
      if (state.selectedTypeTab != 0 && item.type != state.selectedTypeTab) {
        return false;
      }
      // P1-10 (B7): single-level folder filter. '__none__' = no folder.
      final f = _folderFilter;
      if (f == null) return true;
      if (f == '__none__') return item.folderId == null || item.folderId!.isEmpty;
      return item.folderId == f;
    };

    final filtered = state.items.where(matchesTab).toList();

    final favoriteItems = settings.showFavorites
        ? state.items.where((i) => i.isFavorite && matchesTab(i)).toList()
        : <NexItem>[];

    final recentItems = settings.showRecentShortcuts
        ? (state.items.where((i) => i.lastUsedAt != null && matchesTab(i)).toList()
          ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!)))
        : <NexItem>[];
    if (recentItems.length > 5) recentItems.removeRange(5, recentItems.length);

    if (filtered.isEmpty && favoriteItems.isEmpty && recentItems.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return SliverFillRemaining(child: Center(
        child: Text(S.noItemsInCategory, style: TextStyle(color: cs.outline))));
    }

    final cs = Theme.of(context).colorScheme;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.sm, NexTheme.lg,
          120 + MediaQuery.of(context).padding.bottom),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (favoriteItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: NexTheme.sm),
              padding: const EdgeInsets.all(NexTheme.md),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(NexTheme.rMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(S.settingsShowFavorites, cs),
                  for (int i = 0; i < favoriteItems.length; i++)
                    _StaggeredEntrance(
                      index: i,
                      child: _selectableCard(favoriteItems[i]),
                    ),
                ],
              ),
            ),
          if (recentItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: NexTheme.sm),
              padding: const EdgeInsets.all(NexTheme.md),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(NexTheme.rMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(S.settingsShowRecent, cs),
                  for (int i = 0; i < recentItems.length; i++)
                    _StaggeredEntrance(
                      index: i,
                      child: _selectableCard(recentItems[i]),
                    ),
                ],
              ),
            ),
          for (int i = 0; i < filtered.length; i++)
            _StaggeredEntrance(
              index: i,
              child: _selectableCard(filtered[i]),
            ),
        ]),
      ),
    );
  }

  // Shared-element open: marks vault usage then pushes with the unified
  // PageTransitionsTheme (configured in NexTheme). The card's icon/title
  // Heroes (see _VaultItemCard) pair with ItemDetailScreen's header Heroes.
  void _openDetail(BuildContext context, WidgetRef ref, NexItem item) {
    HapticFeedback.selectionClick();
    ref.read(vaultStateProvider.notifier).markUsed(item);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item)));
  }

  // ── P1-10: selection-aware card ──────────────────────────────────────
  // Selecting disables swipe (Dismissible would steal the horizontal drag
  // and cause accidental deletes), so the wrapper is bypassed in batch mode.

  void _onCardTap(NexItem item) {
    if (_selecting) {
      _toggleSelect(item);
    } else {
      _openDetail(context, ref, item);
    }
  }

  Widget _selectableCard(NexItem item) {
    final card = _VaultItemCard(
      item: item,
      selected: _selected.contains(_keyOf(item)),
      onTap: () => _onCardTap(item),
      onLongPress: () => _toggleSelect(item),
    );
    if (_selecting) return card;
    return _VaultSwipeWrapper(
      key: ValueKey('all-${item.uuid}'),
      item: item,
      child: card,
    );
  }

  List<NexItem> _resolveSelected(List<NexItem> all) {
    return all.where((e) => _selected.contains(_keyOf(e))).toList();
  }

  void _selectAllVisible(List<NexItem> visible) {
    HapticFeedback.selectionClick();
    setState(() {
      for (final item in visible) {
        _selected.add(_keyOf(item));
      }
    });
  }

  // ── P1-10 (B7): folder helpers ───────────────────────────────────────

  List<String> _allFolders(List<NexItem> items) {
    final set = <String>{};
    for (final item in items) {
      final f = item.folderId;
      if (f != null && f.trim().isNotEmpty) set.add(f.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  Widget _folderChips(dynamic S, VaultState vaultState) {
    // Hide the row when no folders exist and no filter is active — keeps
    // the default vault view pixel-identical for folder-free users.
    final folders = _allFolders(vaultState.items);
    if (folders.isEmpty && _folderFilter == null) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    Widget chip(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? cs.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(NexTheme.rSm),
            border: Border.all(
                color: active ? cs.secondary : cs.outline),
          ),
          child: Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active
                      ? cs.onSecondaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w500)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: NexTheme.lg, vertical: NexTheme.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(S.folderAll, _folderFilter == null,
                () => setState(() => _folderFilter = null)),
            const SizedBox(width: NexTheme.sm),
            chip(S.folderNoFolder, _folderFilter == '__none__',
                () => setState(() => _folderFilter = '__none__')),
            for (final f in folders) ...[
              const SizedBox(width: NexTheme.sm),
              chip(f, _folderFilter == f,
                  () => setState(() => _folderFilter = f)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _batchMoveToFolder(List<NexItem> targets) async {
    if (targets.isEmpty) return;
    final S = AppLocalizations.of(context);
    final folders = _allFolders(
        ref.read(vaultStateProvider).items);
    final nameC = TextEditingController();
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NexTheme.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(S.folderMoveTitle,
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: NexTheme.md),
                  TextField(
                    controller: nameC,
                    decoration:
                        InputDecoration(hintText: S.folderNewHint),
                    onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                  ),
                  const SizedBox(height: NexTheme.sm),
                  ListTile(
                    title: Text(S.folderNoFolder),
                    onTap: () => Navigator.pop(ctx, ''),
                  ),
                  for (final f in folders)
                    ListTile(
                      title: Text(f),
                      onTap: () => Navigator.pop(ctx, f),
                    ),
                  const SizedBox(height: NexTheme.sm),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, nameC.text.trim()),
                    child: Text(S.add),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (picked == null) return;
    HapticFeedback.mediumImpact();
    // Empty string from the sheet = explicit "no folder" → null.
    await ref
        .read(vaultStateProvider.notifier)
        .moveItemsToFolder(targets, picked.isEmpty ? null : picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.batchUpdated(targets.length))),
      );
    }
    _clearSelection();
  }

  Future<void> _batchDelete(List<NexItem> targets) async {
    if (targets.isEmpty) return;
    HapticFeedback.heavyImpact();
    final S = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteTitle),
        content: Text(S.batchDeleted(targets.length)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(vaultStateProvider.notifier).deleteItems(targets);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.batchDeleted(targets.length))),
      );
    }
    _clearSelection();
  }

  Future<void> _batchFavorite(List<NexItem> targets) async {
    if (targets.isEmpty) return;
    HapticFeedback.mediumImpact();
    final S = AppLocalizations.of(context);
    await ref.read(vaultStateProvider.notifier).setFavoriteAll(targets, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.batchUpdated(targets.length))),
      );
    }
    _clearSelection();
  }

  // B6 move = change entry type (1/2/3). B7 adds the folder section below,
  // reusing the same notifier batch path.
  Future<void> _batchMove(List<NexItem> targets) async {
    if (targets.isEmpty) return;
    final S = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(NexTheme.lg),
              child: Text(S.batchMoveTitle,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const NexIcon(NexIconType.person, size: 20),
              title: Text(S.typeLogin),
              onTap: () => Navigator.pop(ctx, 1),
            ),
            ListTile(
              leading: const NexIcon(NexIconType.creditCard, size: 20),
              title: Text(S.typeCard),
              onTap: () => Navigator.pop(ctx, 2),
            ),
            ListTile(
              leading: const NexIcon(NexIconType.stickyNote, size: 20),
              title: Text(S.typeNote),
              onTap: () => Navigator.pop(ctx, 3),
            ),
            const Divider(),
            ListTile(
              leading: const NexIcon(NexIconType.copy, size: 20),
              title: Text(S.folderMoveTitle),
              onTap: () => Navigator.pop(ctx, -1),
            ),
            const SizedBox(height: NexTheme.sm),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked == -1) {
      if (context.mounted) await _batchMoveToFolder(targets);
      return;
    }
    HapticFeedback.mediumImpact();
    await ref.read(vaultStateProvider.notifier).moveItemsToType(targets, picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.batchUpdated(targets.length))),
      );
    }
    _clearSelection();
  }

  Widget _batchBar(dynamic S, VaultState vaultState) {
    final cs = Theme.of(context).colorScheme;
    final targets = _resolveSelected(vaultState.items);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: NexTheme.md, vertical: NexTheme.sm),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(NexTheme.rMd),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: NexIcon(NexIconType.close, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: NexTheme.sm),
          Expanded(
            child: Text(
              S.batchSelected(_selected.length),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => _selectAllVisible(vaultState.items),
            child: Text(S.batchSelectAll),
          ),
          IconButton(
            tooltip: S.batchFavorite,
            onPressed: targets.isEmpty ? null : () => _batchFavorite(targets),
            icon: NexIcon(NexIconType.heart, size: 20,
                color: cs.onPrimaryContainer),
          ),
          IconButton(
            tooltip: S.batchMove,
            onPressed: targets.isEmpty ? null : () => _batchMove(targets),
            icon: NexIcon(NexIconType.copy, size: 20,
                color: cs.onPrimaryContainer),
          ),
          IconButton(
            tooltip: S.delete,
            onPressed: targets.isEmpty ? null : () => _batchDelete(targets),
            icon: NexIcon(NexIconType.trash, size: 20, color: cs.error),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NexTheme.sm, top: NexTheme.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref, dynamic S, VaultState vaultState) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final vaultNotifier = ref.read(vaultStateProvider.notifier);

    final tabs = <(String, int)>[(S.tabAll, 0)];
    if (settings.navPasswords) tabs.add((S.onboardingNavPasswords, 1));
    if (settings.navCards) tabs.add((S.onboardingNavCards, 2));
    if (settings.navAuthenticators) tabs.add((S.onboardingNavAuthenticators, 4));
    if (settings.navPasskeys) tabs.add((S.onboardingNavPasskeys, 5));
    tabs.add((S.tabNotes, 3));

    if (!tabs.any((t) => t.$2 == vaultState.selectedTypeTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vaultNotifier.setTab(0);
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: NexTheme.sm),
            _tabChip(ref, tabs[i].$1, tabs[i].$2, vaultState.selectedTypeTab),
          ],
        ],
      ),
    );
  }
}

// ── Vault item card ────────────────────────────────────────────────────

class _VaultItemCard extends ConsumerWidget {
  final NexItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  const _VaultItemCard(
      {required this.item, this.onTap, this.onLongPress, this.selected = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(appSettingsNotifierProvider);
    NexIconType iconType;
    Color iconColor;
    switch (item.type) {
      case 1: iconType = NexIconType.person; iconColor = cs.primary; break;
      case 2: iconType = NexIconType.creditCard; iconColor = cs.tertiary; break;
      case 3: iconType = NexIconType.stickyNote; iconColor = NexTheme.warning; break;
      case 4: iconType = NexIconType.clock; iconColor = cs.error; break;
      default: iconType = NexIconType.key; iconColor = cs.primary;
    }

    final hasTotp = item.hasTotp;
    final showLinkedAuth = settings.cardShowLinkedAuth && hasTotp;
    final hideOtherWhenAuth = settings.cardHideOtherWhenAuth && showLinkedAuth;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? cs.primaryContainer.withValues(alpha: 0.45) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(NexTheme.md),
          child: Row(
          children: [
            // P1-10: selection checkbox replaces the icon badge in batch mode.
            if (selected)
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(NexTheme.rSm),
                ),
                child: Center(
                    child: NexIcon(NexIconType.shield,
                        size: 18, color: cs.onPrimary)),
              )
            else
            Hero(
              tag: 'vault-icon-${item.uuid}',
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(NexTheme.rSm),
                ),
                child: Center(child: NexIcon(iconType, size: 18, color: iconColor)),
              ),
            ),
            const SizedBox(width: NexTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'vault-title-${item.uuid}',
                          // Hero flight needs a Material ancestor for text.
                          child: Material(
                            color: Colors.transparent,
                            child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                      if (showLinkedAuth) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text('TOTP', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  if (!hideOtherWhenAuth) ...[
                    const SizedBox(height: 2),
                    if (item.type == 4) ...[
                      if (settings.authShowIssuer)
                        Text(item.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (settings.authShowAccount)
                        Text(item.username, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ] else ...[
                      if (settings.cardShowUsername)
                        Text(item.username, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (settings.cardShowWebsite && item.website.isNotEmpty)
                        Text(item.website, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── P0-2: swipeable wrapper ──────────────────────────────────────────────
// Right swipe (startToEnd) = delete; left swipe (endToStart) = favorite
// toggle + username copy. Haptic feedback on every swipe action (1Password
// swipe Archive/Delete parity). No third-party deps — core Dismissible only.
class _VaultSwipeWrapper extends ConsumerWidget {
  final NexItem item;
  final Widget child;

  const _VaultSwipeWrapper({super.key, required this.item, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(vaultStateProvider.notifier);

    return Dismissible(
      key: key ?? ValueKey(item.uuid),
      // Reserve the destructive action for the explicit right-swipe;
      // left-swipe performs non-destructive actions and never dismisses.
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          await notifier.toggleFavorite(item);
          if (item.username.isNotEmpty) {
            await Clipboard.setData(ClipboardData(text: item.username));
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(item.isFavorite
                    ? 'Removed from favorites'
                    : 'Favorited · username copied'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return false;
        }
        // startToEnd (delete): require explicit confirm to avoid accidents.
        HapticFeedback.heavyImpact();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete item?'),
            content: Text(
                '"${item.name}" will be removed from this vault.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        );
        return confirmed == true;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await notifier.deleteItem(item);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted "${item.name}"')),
            );
          }
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: NexTheme.lg),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(NexTheme.rMd),
        ),
        child: NexIcon(NexIconType.close, size: 22, color: cs.onErrorContainer),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: NexTheme.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(NexTheme.rMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            NexIcon(NexIconType.copy,
                size: 20, color: cs.onPrimaryContainer),
            const SizedBox(width: NexTheme.sm),
            NexIcon(
                item.isFavorite
                    ? NexIconType.lock
                    : NexIconType.shield,
                size: 20,
                color: cs.onPrimaryContainer),
          ],
        ),
      ),
      child: child,
    );
  }
}

// ── P0-1: staggered list entrance (AnimatedList-equivalent perception) ───
// SliverAnimatedList would require manual insert/remove diffing against the
// Riverpod-filtered list (high risk); staggered fade+slide gives the same
// perceived smoothness with zero state-sync risk.
class _StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredEntrance({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    // Cap the stagger so long lists don't feel laggy.
    final delay = Duration(milliseconds: (index.clamp(0, 8)) * 40);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

// ── P0-1: skeleton shimmer loading state ─────────────────────────────────
class _VaultSkeletonSliver extends StatelessWidget {
  const _VaultSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.sm, NexTheme.lg,
          120 + MediaQuery.of(context).padding.bottom),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, _) => const Padding(
            padding: EdgeInsets.only(bottom: NexTheme.sm),
            child: _ShimmerCard(),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        height: 68,
        padding: const EdgeInsets.all(NexTheme.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(NexTheme.rMd),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(
                    alpha: 0.4 + 0.3 * _ctrl.value),
                borderRadius: BorderRadius.circular(NexTheme.rSm),
              ),
            ),
            const SizedBox(width: NexTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.7 - 0.3 * _ctrl.value),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4 + 0.3 * (1 - _ctrl.value)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
