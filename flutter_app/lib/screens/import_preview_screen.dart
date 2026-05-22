import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nex_item.dart';
import '../state/unlock_state.dart';
import '../state/vault_state_notifier.dart';
import '../theme/nex_theme.dart';
import '../widgets/nex_icons.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  final List<NexItem> items;
  final String formatName;

  const ImportPreviewScreen({
    super.key,
    required this.items,
    required this.formatName,
  });

  @override
  ConsumerState<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  late final Set<int> _selectedIndices;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selectedIndices = Set<int>.from(List.generate(widget.items.length, (i) => i));
  }

  Future<void> _importSelected() async {
    setState(() => _importing = true);

    try {
      final repository = ref.read(repositoryProvider);
      final derivedKey = ref.read(unlockStateProvider).derivedKey!;

      int imported = 0;
      for (final idx in _selectedIndices) {
        await repository.saveItem(item: widget.items[idx], derivedKey: derivedKey);
        imported++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported credentials')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import Preview (${widget.formatName})'),
        actions: [
          TextButton(
            onPressed: _importing ? null : () {
              setState(() {
                if (_selectedIndices.length == widget.items.length) {
                  _selectedIndices.clear();
                } else {
                  _selectedIndices = Set<int>.from(
                      List.generate(widget.items.length, (i) => i));
                }
              });
            },
            child: Text(_selectedIndices.length == widget.items.length
                ? 'Deselect All'
                : 'Select All'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                NexIcon(NexIconType.info, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedIndices.length} of ${widget.items.length} items selected',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (ctx, idx) {
                final item = widget.items[idx];
                final isSelected = _selectedIndices.contains(idx);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIndices.add(idx);
                      } else {
                        _selectedIndices.remove(idx);
                      }
                    });
                  },
                  title: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    item.fields
                        .where((f) => f.name == 'username')
                        .map((f) => f.value)
                        .firstOrNull ?? '',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  secondary: SizedBox(
                    width: 40, height: 40,
                    child: Center(
                      child: NexIcon(
                        item.type == 1 ? NexIconType.person : NexIconType.key,
                        size: 20,
                        color: cs.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selectedIndices.isEmpty || _importing
                ? null
                : _importSelected,
            icon: _importing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const NexIcon(NexIconType.plus, size: 18, color: Colors.white),
            label: Text(_importing
                ? 'Importing...'
                : 'Import ${_selectedIndices.length} items'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NexTheme.rMd)),
            ),
          ),
        ),
      ),
    );
  }
}
