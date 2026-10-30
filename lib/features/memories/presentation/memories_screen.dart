import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/data/affection_repository.dart';
import '../../affection/domain/models.dart';

class MemoriesScreen extends ConsumerStatefulWidget {
  const MemoriesScreen({super.key, this.studio = false});
  final bool studio;
  @override
  ConsumerState<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends ConsumerState<MemoriesScreen> {
  bool _favorites = false;
  bool _more = true, _loading = false;
  final List<SavedMemory> _older = [];
  Future<void> _loadOlder(List<SavedMemory> recent) async {
    final before = _older.isNotEmpty ? _older.last : recent.last;
    if (before.createdAt == null) return;
    setState(() => _loading = true);
    try {
      final items = await MemoryRepository(
        ref.read(affectionRepositoryProvider)!,
      ).older(before);
      if (mounted) {
        setState(() {
          _older.addAll(items);
          _more = items.length == 30;
        });
      }
    } catch (_) {
      if (mounted) {
        notify(context, 'Older memories couldn’t load. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.studio ? null : ref.watch(memoriesProvider);
    final recent = state?.value ?? <SavedMemory>[];
    final seen = <String>{};
    final memories = [...recent, ..._older]
        .where((m) => seen.add(m.id))
        .where((m) => !_favorites || m.favorite)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 36),
      child: PageBody(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('The little things we keep'),
            const SizedBox(height: 12),
            const Text(
              'Our memory book.',
              style: TextStyle(
                fontSize: 33,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Some moments deserve a forever kind of place.',
              style: TextStyle(color: Palette.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('All memories'),
                  selected: !_favorites,
                  onSelected: (_) => setState(() => _favorites = false),
                  showCheckmark: false,
                  selectedColor: Palette.blush,
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Favorites ♡'),
                  selected: _favorites,
                  onSelected: (_) => setState(() => _favorites = true),
                  showCheckmark: false,
                  selectedColor: Palette.blush,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (state?.isLoading == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (state?.hasError == true)
              ErrorNotice(
                state!.error!,
                retry: () => ref.invalidate(memoriesProvider),
              ),
            if (memories.isEmpty &&
                state?.isLoading != true &&
                state?.hasError != true)
              EmptyState(
                title: _favorites
                    ? 'Your favorites will feel at home here.'
                    : 'The first page is waiting.',
                message: widget.studio
                    ? 'Your own saved moments will live here once your accounts are connected.'
                    : _favorites
                    ? 'Tap the little heart on a memory to keep it close.'
                    : 'After opening a surprise, save it here. A tiny scrapbook of all the ways you love.',
                icon: Icons.auto_stories_outlined,
                action: TextButton(
                  onPressed: () =>
                      context.go(widget.studio ? '/studio/inbox' : '/inbox'),
                  child: const Text('Visit our little mailbox  ›'),
                ),
              ),
            for (final memory in memories)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PaperCard(
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 78,
                        decoration: BoxDecoration(
                          color: Palette.lavender.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Palette.rose,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory.caption,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              shortDate(memory.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.muted,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () => context.push(
                                '/moment/${memory.momentId}/play',
                              ),
                              child: const Text(
                                'Feel it all over again ›',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: memory.favorite
                                ? 'Remove favorite'
                                : 'Mark favorite',
                            onPressed: () async {
                              try {
                                await MemoryRepository(
                                  ref.read(affectionRepositoryProvider)!,
                                ).favorite(memory);
                                final olderIndex = _older.indexWhere(
                                  (item) => item.id == memory.id,
                                );
                                if (mounted && olderIndex >= 0) {
                                  setState(
                                    () => _older[olderIndex] = SavedMemory(
                                      id: memory.id,
                                      momentId: memory.momentId,
                                      caption: memory.caption,
                                      favorite: !memory.favorite,
                                      createdAt: memory.createdAt,
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  notify(
                                    context,
                                    'This memory couldn’t update. Try again.',
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              memory.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: Palette.rose,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove from my book',
                            icon: const Icon(
                              Icons.bookmark_remove_outlined,
                              size: 19,
                              color: Palette.muted,
                            ),
                            onPressed: () async {
                              final yes = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Let this page go?'),
                                  content: const Text(
                                    'This removes it from your book. The original moment stays in your history.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Keep it'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (yes == true) {
                                try {
                                  await MemoryRepository(
                                    ref.read(affectionRepositoryProvider)!,
                                  ).remove(memory.id);
                                  if (mounted) {
                                    setState(
                                      () => _older.removeWhere(
                                        (item) => item.id == memory.id,
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    notify(
                                      context,
                                      'Your memory is still safe. Try again online.',
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_more && recent.length >= 30)
              Center(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _loadOlder(recent),
                  child: Text(
                    _loading
                        ? "Finding more memories…"
                        : "A few older memories",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
