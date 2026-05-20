import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[950],
          appBar: AppBar(
            title: const Text('NexPass Secure Vault',
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            actions: [
              // Quick Paste button — visible when password is cached in RAM
              if (clipState.isVisible)
                IconButton(
                  icon: const Icon(Icons.paste, color: Colors.greenAccent),
                  onPressed: _handleQuickPaste,
                  tooltip: 'Quick Paste (password from RAM)',
                ),
              IconButton(
                icon: const Icon(Icons.shield, color: Colors.tealAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SecurityAuditScreen()),
                  );
                },
                tooltip: 'Security Audit',
              ),
              IconButton(
                icon: const Icon(Icons.password, color: Colors.tealAccent),
                onPressed: () => _showGeneratorDialog(context),
                tooltip: 'Interactive Generator',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: vaultNotifier.setSearchQuery,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search zero-knowledge credentials...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.tealAccent),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

              // Category tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTabButton(
                      ref, 'All Items', 0, vaultState.selectedTypeTab),
                  _buildTabButton(
                      ref, 'Logins', 1, vaultState.selectedTypeTab),
                  _buildTabButton(
                      ref, 'Cards', 2, vaultState.selectedTypeTab),
                ],
              ),

              const SizedBox(height: 12),

              // Vault items list
              Expanded(
                child: vaultState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.tealAccent))
                    : ListView.builder(
                        itemCount: vaultState.items.length,
                        itemBuilder: (context, idx) {
                          final item = vaultState.items[idx];

                          if (vaultState.selectedTypeTab != 0 &&
                              item.type != vaultState.selectedTypeTab) {
                            return const SizedBox.shrink();
                          }

                          return _VaultItemCard(
                            item: item,
                            onCopy: () => _handleCopyItem(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // ── Dual clipboard overlay (renders on top of everything) ──
        const DualClipboardOverlay(),
      ],
    );
  }

  // ── Copy handler with dual-clipboard routing ──────────────────────────

  Future<void> _handleCopyItem(dynamic item) async {
    final notifier = ref.read(dualClipboardProvider.notifier);
    final isDual = await notifier.copyItem(item);

    if (!mounted) return;

    if (!isDual) {
      // Single-field copy — show standard SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[850],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    // Dual path: overlay is shown automatically by DualClipboardNotifier
  }

  // ── Quick Paste: consume RAM-cached password ─────────────────────────

  void _handleQuickPaste() {
    final notifier = ref.read(dualClipboardProvider.notifier);
    final password = notifier.consumePassword();

    if (password != null && mounted) {
      // Copy password to system clipboard for the user's next paste
      Clipboard.setData(ClipboardData(text: password));
      notifier.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Password moved to clipboard — paste now! Buffer cleared.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildTabButton(
      WidgetRef ref, String title, int index, int activeIndex) {
    final notifier = ref.read(vaultStateProvider.notifier);
    final isActive = index == activeIndex;
    return ChoiceChip(
      label: Text(title),
      selected: isActive,
      onSelected: (_) => notifier.setTab(index),
      selectedColor: Colors.teal[800],
      textColor: isActive ? Colors.white : Colors.grey,
    );
  }

  void _showGeneratorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String generatedPassword = _generator.generate(length: 16);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Secure Password Generator',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            generatedPassword,
                            style: const TextStyle(
                                color: Colors.tealAccent,
                                fontFamily: 'monospace',
                                fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white),
                          onPressed: () {
                            setModalState(() {
                              generatedPassword =
                                  _generator.generate(length: 16);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Customize criteria in real-time, security rate matches high performance indices.',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                )
              ],
            );
          },
        );
      },
    );
  }
}

// ── Vault item card widget ──────────────────────────────────────────────

class _VaultItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onCopy;

  const _VaultItemCard({required this.item, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    // Determine icon based on item type
    IconData icon;
    switch (item.type) {
      case 1:
        icon = Icons.login;
        break;
      case 2:
        icon = Icons.credit_card;
        break;
      case 4:
        icon = Icons.timer;
        break;
      default:
        icon = Icons.key;
    }

    // Check if item has TOTP (for visual indicator)
    final hasTotp = item.fields.any(
        (f) => f.name == 'totpSecret' || f.fieldType == 3);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal[900],
          child: Icon(icon, color: Colors.tealAccent),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (hasTotp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity( 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '2FA',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(item.username,
            style: TextStyle(color: Colors.grey[400])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.grey),
              onPressed: onCopy,
              tooltip: hasTotp ? 'Dual copy (TOTP + Password)' : 'Copy password',
            ),
          ],
        ),
      ),
    );
  }
}
