import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../main.dart';
import '../state/vault_state_notifier.dart';
import '../services/clipboard_service.dart';
import '../services/password_generator_service.dart';
import 'clipboard_overlay.dart';
import 'security_audit_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final _searchController = TextEditingController();
  final _generator = PasswordGeneratorService();

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultStateProvider);
    final vaultNotifier = ref.read(vaultStateProvider.notifier);
    final clipState = ref.watch(dualClipboardProvider);
    final S = AppLocalizations.of(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          appBar: AppBar(
            backgroundColor: const Color(0xFF161B22),
            elevation: 0,
            centerTitle: false,
            title: Row(
              children: [
                _iconBadge('\u{1F6E1}', const Color(0xFF2DD4BF)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.appTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                    Text(S.vaultSubtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                  ],
                ),
              ],
            ),
            actions: [
              // Language switcher
              GestureDetector(
                onTap: () => _showLanguageDialog(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Text('\u{1F310}', style: TextStyle(fontSize: 20)),
                ),
              ),
              if (clipState.isVisible)
                _iconBtn('\u{1F4CB}', const Color(0xFF3FB950), _handleQuickPaste, S.quickPaste),
              _iconBtn('\u{1F6E1}', const Color(0xFF58A6FF), () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SecurityAuditScreen())), S.securityAudit),
              _iconBtn('\u{1F510}', const Color(0xFF58A6FF), () => _showGeneratorDialog(context), S.generator),
            ],
          ),
          body: Column(
            children: [
              // Search
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: vaultNotifier.setSearchQuery,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: S.searchHint,
                    hintStyle: const TextStyle(color: Color(0xFF484F58)),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Text('\u{1F50D}', style: TextStyle(fontSize: 16)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF21262D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF21262D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
                    ),
                  ),
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _tabChip(ref, '\u{2714} ${S.tabAll}', 0, vaultState.selectedTypeTab),
                    const SizedBox(width: 8),
                    _tabChip(ref, '\u{1F464} ${S.tabLogins}', 1, vaultState.selectedTypeTab),
                    const SizedBox(width: 8),
                    _tabChip(ref, '\u{1F4B3} ${S.tabCards}', 2, vaultState.selectedTypeTab),
                    const SizedBox(width: 8),
                    _tabChip(ref, '\u{1F4DD} ${S.tabNotes}', 3, vaultState.selectedTypeTab),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: vaultState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DD4BF)))
                    : vaultState.items.isEmpty
                        ? _emptyState(S)
                        : _itemList(vaultState),
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2DD4BF), Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
        const DualClipboardOverlay(),
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

  Widget _iconBtn(String emoji, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(onTap: onTap, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(emoji, style: TextStyle(fontSize: 20, color: color)),
      )),
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

  Widget _itemList(VaultState state) {
    final S = AppLocalizations.of(context);
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

  // ── Language dialog ──────────────────────────────────────────────────

  void _showLanguageDialog(BuildContext context) {
    final languages = [
      ('en', 'English', '\u{1F1EC}\u{1F1E7}'),
      ('zh', '中文', '\u{1F1E8}\u{1F1F3}'),
      ('ja', '日本語', '\u{1F1EF}\u{1F1F5}'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((l) {
            final current = ref.read(localeProvider).languageCode == l.$1;
            return ListTile(
              leading: Text(l.$3, style: const TextStyle(fontSize: 24)),
              title: Text(l.$2, style: TextStyle(color: current ? const Color(0xFF2DD4BF) : Colors.white)),
              trailing: current ? const Text('\u{2714}', style: TextStyle(color: Color(0xFF2DD4BF), fontSize: 18)) : null,
              onTap: () {
                ref.read(localeProvider.notifier).state = Locale(l.$1);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────

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

  void _handleQuickPaste() {
    final S = AppLocalizations.of(context);
    final notifier = ref.read(dualClipboardProvider.notifier);
    final password = notifier.consumePassword();
    if (password != null && mounted) {
      Clipboard.setData(ClipboardData(text: password));
      notifier.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.passwordReadyToPaste), behavior: SnackBarBehavior.floating),
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

  void _showAddDialog(BuildContext context) {
    final S = AppLocalizations.of(context);
    final nameC = TextEditingController();
    final userC = TextEditingController();
    final passC = TextEditingController();
    int type = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Text(S.addCredential, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameC, S.nameLabel),
                const SizedBox(height: 12),
                _field(userC, S.usernameLabel),
                const SizedBox(height: 12),
                _field(passC, S.passwordLabel),
                const SizedBox(height: 16),
                Row(children: [
                  _typeBtn(S.typeLogin, 1, type, (v) => setModalState(() => type = v)),
                  const SizedBox(width: 8),
                  _typeBtn(S.typeCard, 2, type, (v) => setModalState(() => type = v)),
                  const SizedBox(width: 8),
                  _typeBtn(S.typeNote, 3, type, (v) => setModalState(() => type = v)),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.cancel, style: const TextStyle(color: Color(0xFF8B949E)))),
            FilledButton(
              onPressed: () {
                if (nameC.text.isNotEmpty && passC.text.isNotEmpty) {
                  ref.read(vaultStateProvider.notifier).addNewCredential(
                      title: nameC.text, itemType: type, username: userC.text, password: passC.text);
                  Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2DD4BF)),
              child: Text(S.add, style: const TextStyle(color: Color(0xFF0D1117))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(controller: c, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF484F58)),
        filled: true, fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF21262D))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF21262D))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
  }

  Widget _typeBtn(String label, int value, int current, Function(int) onSelect) {
    final isActive = value == current;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1F6FEB).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? const Color(0xFF1F6FEB) : const Color(0xFF21262D)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFF58A6FF) : const Color(0xFF8B949E))),
      ),
    );
  }

  void _showGeneratorDialog(BuildContext context) {
    final S = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        String gen = _generator.generate(length: 20);
        return StatefulBuilder(
          builder: (context, setModalState) {
            final score = _generator.evaluateStrength(gen);
            final label = score >= 0.85 ? S.excellent : score >= 0.6 ? S.strong : S.fair;
            final color = score >= 0.85 ? const Color(0xFF3FB950) : score >= 0.6 ? const Color(0xFF2DD4BF) : const Color(0xFFD29922);
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              title: Text(S.passwordGenerator, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF21262D))),
                    child: Row(children: [
                      Expanded(child: SelectableText(gen, style: const TextStyle(color: Color(0xFF2DD4BF), fontFamily: 'monospace', fontSize: 15))),
                      GestureDetector(
                        onTap: () => Clipboard.setData(ClipboardData(text: gen)),
                        child: const Text('\u{1F4CB}', style: TextStyle(fontSize: 16)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(S.strengthLabel(label), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(S.close, style: const TextStyle(color: Color(0xFF8B949E)))),
                FilledButton(
                  onPressed: () => setModalState(() => gen = _generator.generate(length: 20)),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2DD4BF)),
                  child: Text(S.regenerate, style: const TextStyle(color: Color(0xFF0D1117))),
                ),
              ],
            );
          },
        );
      },
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
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: bg.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        title: Row(children: [
          Expanded(child: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (hasTotp) Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
