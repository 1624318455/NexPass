import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../state/vault_state_notifier.dart';
import '../services/clipboard_service.dart';
import '../services/password_generator_service.dart';
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
  final _generator = PasswordGeneratorService();
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final S = AppLocalizations.of(context);
    final pages = [
      _VaultPage(searchController: _searchController, generator: _generator),
      const SettingsScreen(),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          body: pages[_navIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              border: Border(top: BorderSide(color: Color(0xFF21262D), width: 0.5)),
            ),
            child: BottomNavigationBar(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              selectedItemColor: const Color(0xFF2DD4BF),
              unselectedItemColor: const Color(0xFF8B949E),
              items: [
                BottomNavigationBarItem(
                  icon: const Text('\u{1F510}', style: TextStyle(fontSize: 22)),
                  activeIcon: const Text('\u{1F510}', style: TextStyle(fontSize: 22)),
                  label: S.tabVault,
                ),
                BottomNavigationBarItem(
                  icon: const Text('\u{2699}\u{FE0F}', style: TextStyle(fontSize: 22)),
                  activeIcon: const Text('\u{2699}\u{FE0F}', style: TextStyle(fontSize: 22)),
                  label: S.tabSettings,
                ),
              ],
            ),
          ),
        ),
        const DualClipboardOverlay(),
      ],
    );
  }
}

// ── Vault page (extracted from old MainScreen) ────────────────────────

class _VaultPage extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final PasswordGeneratorService generator;

  const _VaultPage({required this.searchController, required this.generator});

  @override
  ConsumerState<_VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<_VaultPage> {
  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultStateProvider);
    final vaultNotifier = ref.read(vaultStateProvider.notifier);
    final S = AppLocalizations.of(context);

    return Column(
      children: [
        // App bar
        Container(
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 8),
          decoration: const BoxDecoration(color: Color(0xFF161B22)),
          child: Row(
            children: [
              _iconBadge('\u{1F6E1}', const Color(0xFF2DD4BF)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.appTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                  Text(S.vaultSubtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityAuditScreen())),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('\u{1F6E1}', style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),

        // Search
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: widget.searchController,
            onChanged: vaultNotifier.setSearchQuery,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: S.searchHint,
              hintStyle: const TextStyle(color: Color(0xFF484F58)),
              prefixIcon: const Padding(padding: EdgeInsets.only(left: 12, right: 8), child: Text('\u{1F50D}', style: TextStyle(fontSize: 16))),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF21262D))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF21262D))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5)),
            ),
          ),
        ),

        // Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            _tabChip(ref, '\u{2714} ${S.tabAll}', 0, vaultState.selectedTypeTab),
            const SizedBox(width: 8),
            _tabChip(ref, '\u{1F464} ${S.tabLogins}', 1, vaultState.selectedTypeTab),
            const SizedBox(width: 8),
            _tabChip(ref, '\u{1F4B3} ${S.tabCards}', 2, vaultState.selectedTypeTab),
            const SizedBox(width: 8),
            _tabChip(ref, '\u{1F4DD} ${S.tabNotes}', 3, vaultState.selectedTypeTab),
          ]),
        ),

        const SizedBox(height: 8),

        // List
        Expanded(
          child: vaultState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DD4BF)))
              : vaultState.items.isEmpty
                  ? _emptyState(S)
                  : _itemList(vaultState, S),
        ),
      ],
    );
  }

  Widget _iconBadge(String emoji, Color bg) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [bg, bg.withOpacity(0.7)]), borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    );
  }

  Widget _tabChip(WidgetRef ref, String label, int index, int activeIndex) {
    final isActive = index == activeIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(vaultStateProvider.notifier).setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1F6FEB).withOpacity(0.15) : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? const Color(0xFF1F6FEB) : const Color(0xFF21262D)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF8B949E),
          )),
        ),
      ),
    );
  }

  Widget _emptyState(S) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('\u{1F512}', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text(S.vaultEmpty, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Text(S.vaultEmptyHint, style: const TextStyle(color: Color(0xFF484F58), fontSize: 13)),
    ]));
  }

  Widget _itemList(VaultState state, S) {
    final filtered = state.items.where((item) {
      if (state.selectedTypeTab != 0 && item.type != state.selectedTypeTab) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) return Center(child: Text(S.noItemsInCategory, style: const TextStyle(color: Color(0xFF484F58))));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (context, idx) => _VaultItemCard(item: filtered[idx],
        onCopy: () => _handleCopyItem(filtered[idx]),
        onDelete: () => _confirmDelete(filtered[idx])),
    );
  }

  Future<void> _handleCopyItem(dynamic item) async {
    final S = AppLocalizations.of(context);
    final isDual = await ref.read(dualClipboardProvider.notifier).copyItem(item);
    if (!mounted) return;
    if (!isDual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.passwordCopied), behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF161B22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
    }
  }

  void _confirmDelete(dynamic item) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text(S.deleteTitle, style: const TextStyle(color: Colors.white)),
        content: Text(S.deleteConfirm(item.name), style: const TextStyle(color: Color(0xFF8B949E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: const TextStyle(color: Color(0xFF8B949E)))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); ref.read(vaultStateProvider.notifier).deleteItem(item); },
            child: Text(S.delete, style: const TextStyle(color: Color(0xFFF85149))),
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
    String emoji;
    Color bg;
    switch (item.type) {
      case 1: emoji = '\u{1F464}'; bg = const Color(0xFF1F6FEB); break;
      case 2: emoji = '\u{1F4B3}'; bg = const Color(0xFF8B5CF6); break;
      case 3: emoji = '\u{1F4DD}'; bg = const Color(0xFFD29922); break;
      case 4: emoji = '\u{23F0}'; bg = const Color(0xFFF97583); break;
      default: emoji = '\u{1F511}'; bg = const Color(0xFF2DD4BF);
    }
    final hasTotp = item.fields.any((f) => f.name == 'totpSecret' || f.fieldType == 3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF21262D))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16)))),
        title: Row(children: [
          Expanded(child: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (hasTotp) Container(
            margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF2DD4BF).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: const Text('2FA', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
        subtitle: Text(item.username, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(onTap: onCopy, child: const Padding(padding: EdgeInsets.all(6), child: Text('\u{1F4CB}', style: TextStyle(fontSize: 16)))),
          GestureDetector(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(6), child: Text('\u{1F5D1}', style: TextStyle(fontSize: 16)))),
        ]),
      ),
    );
  }
}
