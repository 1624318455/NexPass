import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
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
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: NexTheme.surface,
              border: Border(top: BorderSide(color: NexTheme.border, width: 0.5)),
            ),
            child: NavigationBar(
              selectedIndex: _navIndex,
              onDestinationSelected: (i) => setState(() => _navIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 64,
              destinations: [
                NavigationDestination(icon: NexIcon(NexIconType.lock, size: 22), label: S.tabVault),
                NavigationDestination(icon: NexIcon(NexIconType.gear, size: 22), label: S.tabSettings),
              ],
            ),
          ),
        ),
        const DualClipboardOverlay(),
      ],
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

    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(NexTheme.lg, MediaQuery.of(context).padding.top + 12, NexTheme.lg, NexTheme.lg),
            decoration: const BoxDecoration(color: NexTheme.surface),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [NexTheme.primary, NexTheme.primaryGlow]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: NexIcon(NexIconType.shield, size: 18, color: NexTheme.textPrimary)),
                ),
                const SizedBox(width: 10),
                Text(S.appTitle, style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: NexTheme.textPrimary, letterSpacing: -0.3)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityAuditScreen())),
                  child: const NexIcon(NexIconType.shield, size: 20, color: NexTheme.textSecondary),
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
              style: const TextStyle(color: NexTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: S.searchHint,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: NexIcon(NexIconType.search, size: 18),
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
            child: Row(
              children: [
                _tabChip(ref, S.tabAll, NexIconType.check, 0, vaultState.selectedTypeTab),
                const SizedBox(width: NexTheme.sm),
                _tabChip(ref, S.tabLogins, NexIconType.person, 1, vaultState.selectedTypeTab),
                const SizedBox(width: NexTheme.sm),
                _tabChip(ref, S.tabCards, NexIconType.globe, 2, vaultState.selectedTypeTab),
                const SizedBox(width: NexTheme.sm),
                _tabChip(ref, S.tabNotes, NexIconType.stickyNote, 3, vaultState.selectedTypeTab),
              ],
            ),
          ),
        ),

        // ── Items ───────────────────────────────────────
        if (vaultState.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: NexTheme.primary)),
          )
        else if (vaultState.items.isEmpty)
          SliverFillRemaining(child: _emptyState(S))
        else
          _itemSliverList(vaultState, S),
      ],
    );
  }

  Widget _tabChip(WidgetRef ref, String label, NexIconType icon, int index, int activeIndex) {
    final isActive = index == activeIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(vaultStateProvider.notifier).setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? NexTheme.primaryDim : NexTheme.surface,
            borderRadius: BorderRadius.circular(NexTheme.rSm),
            border: Border.all(color: isActive ? NexTheme.primary : NexTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NexIcon(icon, size: 13, color: isActive ? NexTheme.primary : NexTheme.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? NexTheme.primary : NexTheme.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(S) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const NexIcon(NexIconType.lock, size: 56, color: NexTheme.textMuted),
      const SizedBox(height: NexTheme.xl),
      Text(S.vaultEmpty, style: const TextStyle(color: NexTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: NexTheme.sm),
      Text(S.vaultEmptyHint, style: const TextStyle(color: NexTheme.textMuted, fontSize: 13)),
    ]));
  }

  Widget _itemSliverList(VaultState state, S) {
    final filtered = state.items.where((item) {
      if (state.selectedTypeTab != 0 && item.type != state.selectedTypeTab) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) {
      return SliverFillRemaining(child: Center(
        child: Text(S.noItemsInCategory, style: const TextStyle(color: NexTheme.textMuted))));
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(NexTheme.lg, NexTheme.sm, NexTheme.lg, 80),
      sliver: SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, idx) => _VaultItemCard(
          item: filtered[idx],
          onCopy: () => _handleCopyItem(filtered[idx]),
          onDelete: () => _confirmDelete(filtered[idx]),
        ),
      ),
    );
  }

  Future<void> _handleCopyItem(dynamic item) async {
    final S = AppLocalizations.of(context);
    final isDual = await ref.read(dualClipboardProvider.notifier).copyItem(item);
    if (!mounted) return;
    if (!isDual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.passwordCopied)),
      );
    }
  }

  void _confirmDelete(dynamic item) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteTitle),
        content: Text(S.deleteConfirm(item.name), style: const TextStyle(color: NexTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: const TextStyle(color: NexTheme.textSecondary))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); ref.read(vaultStateProvider.notifier).deleteItem(item); },
            child: Text(S.delete, style: const TextStyle(color: NexTheme.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Vault item card ────────────────────────────────────────────────────

class _VaultItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const _VaultItemCard({required this.item, required this.onCopy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    NexIconType iconType;
    Color iconColor;
    switch (item.type) {
      case 1: iconType = NexIconType.person; iconColor = NexTheme.primary; break;
      case 2: iconType = NexIconType.globe; iconColor = const Color(0xFF8B5CF6); break;
      case 3: iconType = NexIconType.stickyNote; iconColor = NexTheme.warning; break;
      case 4: iconType = NexIconType.clock; iconColor = const Color(0xFFF97583); break;
      default: iconType = NexIconType.key; iconColor = NexTheme.primary;
    }
    final hasTotp = item.fields.any((f) => f.name == 'totpSecret' || f.fieldType == 3);

    return Container(
      margin: const EdgeInsets.only(bottom: NexTheme.sm),
      padding: const EdgeInsets.all(NexTheme.md),
      decoration: BoxDecoration(
        color: NexTheme.surface,
        borderRadius: BorderRadius.circular(NexTheme.rMd),
        border: Border.all(color: NexTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
                      child: Text(item.name, style: const TextStyle(
                        color: NexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (hasTotp) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: NexTheme.primaryDim,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('TOTP', style: TextStyle(
                        color: NexTheme.primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.username, style: const TextStyle(color: NexTheme.textMuted, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: NexTheme.sm),
          GestureDetector(
            onTap: onCopy,
            child: const Padding(padding: EdgeInsets.all(6), child: NexIcon(NexIconType.copy, size: 16)),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(padding: EdgeInsets.all(6), child: NexIcon(NexIconType.trash, size: 16)),
          ),
        ],
      ),
    );
  }
}
