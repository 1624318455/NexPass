import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../models/nex_item.dart';
import '../state/vault_state_notifier.dart';
import '../services/clipboard_service.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';
import 'clipboard_overlay.dart';
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
                  onPressed: () => _showAddDialog(context),
                  child: const NexIcon(NexIconType.plus, size: 24),
                )
              : null,
        ),
        const DualClipboardOverlay(),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final nameC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();
    int type = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(S.addCredential),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _addField(nameC, S.nameLabel),
                const SizedBox(height: NexTheme.md),
                _addField(userC, S.usernameLabel),
                const SizedBox(height: NexTheme.md),
                _addField(passC, S.passwordLabel),
                const SizedBox(height: NexTheme.lg),
                Row(children: [
                  _typeBtn(S.typeLogin, 1, type, (v) => setModalState(() => type = v)),
                  const SizedBox(width: NexTheme.sm),
                  _typeBtn(S.typeCard, 2, type, (v) => setModalState(() => type = v)),
                  const SizedBox(width: NexTheme.sm),
                  _typeBtn(S.typeNote, 3, type, (v) => setModalState(() => type = v)),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(S.cancel, style: TextStyle(color: cs.onSurfaceVariant))),
            FilledButton(
              onPressed: () {
                if (nameC.text.isNotEmpty && passC.text.isNotEmpty) {
                  ref.read(vaultStateProvider.notifier).addNewCredential(
                    title: nameC.text, itemType: type,
                    username: userC.text, password: passC.text,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: Text(S.add),
            ),
          ],
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

        // ── Search ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.lg, NexTheme.lg, NexTheme.sm),
            child: TextField(
              controller: widget.searchController,
              onChanged: vaultNotifier.setSearchQuery,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: S.searchHint,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: NexIcon(NexIconType.search, size: 18, color: cs.onSurfaceVariant),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
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

        // ── Items ───────────────────────────────────────
        if (vaultState.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
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
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      NexIcon(NexIconType.lock, size: 56, color: cs.outline),
      const SizedBox(height: NexTheme.xl),
      Text(S.vaultEmpty, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
      const SizedBox(height: NexTheme.sm),
      Text(S.vaultEmptyHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
    ]));
  }

  Widget _itemSliverList(VaultState state, S) {
    final settings = ref.watch(appSettingsNotifierProvider);
    final matchesTab = (NexItem item) {
      if (state.selectedTypeTab == 0) return true;
      return item.type == state.selectedTypeTab;
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
      padding: EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.sm, NexTheme.lg, 120 + MediaQuery.of(context).padding.bottom),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (favoriteItems.isNotEmpty) ...[
            _sectionHeader(S.settingsShowFavorites, cs),
            for (final item in favoriteItems)
              _VaultItemCard(
                item: item,
                onCopy: () => _handleCopyItem(item),
                onDelete: () => _confirmDelete(item),
                onToggleFavorite: () => ref.read(vaultStateProvider.notifier).toggleFavorite(item),
              ),
            const SizedBox(height: NexTheme.sm),
          ],
          if (recentItems.isNotEmpty) ...[
            _sectionHeader(S.settingsShowRecent, cs),
            for (final item in recentItems)
              _VaultItemCard(
                item: item,
                onCopy: () => _handleCopyItem(item),
                onDelete: () => _confirmDelete(item),
                onToggleFavorite: () => ref.read(vaultStateProvider.notifier).toggleFavorite(item),
              ),
            const SizedBox(height: NexTheme.sm),
          ],
          for (final item in filtered)
            _VaultItemCard(
              item: item,
              onCopy: () => _handleCopyItem(item),
              onDelete: () => _confirmDelete(item),
              onToggleFavorite: () => ref.read(vaultStateProvider.notifier).toggleFavorite(item),
            ),
        ]),
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

  Future<void> _handleCopyItem(NexItem item) async {
    final S = AppLocalizations.of(context);
    final isDual = await ref.read(dualClipboardProvider.notifier).copyItem(item);
    ref.read(vaultStateProvider.notifier).markUsed(item);
    if (!mounted) return;
    if (!isDual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.passwordCopied)),
      );
    }
  }

  void _confirmDelete(NexItem item) {
    final S = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteTitle),
        content: Text(S.deleteConfirm(item.name), style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: TextStyle(color: cs.onSurfaceVariant))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); ref.read(vaultStateProvider.notifier).deleteItem(item); },
            child: Text(S.delete, style: TextStyle(color: cs.error)),
          ),
        ],
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
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onToggleFavorite;

  const _VaultItemCard({required this.item, required this.onCopy, required this.onDelete, this.onToggleFavorite});

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
      child: Padding(
        padding: const EdgeInsets.all(NexTheme.md),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(NexTheme.rSm),
              ),
              child: Center(child: NexIcon(iconType, size: 18, color: iconColor)),
            ),
            const SizedBox(width: NexTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
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
            const SizedBox(width: NexTheme.sm),
            if (onToggleFavorite != null)
              IconButton(
                onPressed: onToggleFavorite,
                icon: NexIcon(NexIconType.heart, size: 16,
                    color: item.isFavorite ? cs.error : cs.outline),
                iconSize: 16,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            IconButton(
              onPressed: onCopy,
              icon: NexIcon(NexIconType.copy, size: 16, color: cs.onSurfaceVariant),
              iconSize: 16,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              onPressed: onDelete,
              icon: NexIcon(NexIconType.trash, size: 16, color: cs.error.withValues(alpha: 0.6)),
              iconSize: 16,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
