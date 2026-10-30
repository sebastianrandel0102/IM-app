import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../services/providers.dart';
import '../../features/settings/data/settings_repository.dart';
import 'components.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.path,
    required this.child,
    this.studio = false,
  });
  final String path;
  final Widget child;
  final bool studio;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = studio
        ? ['/studio', '/studio/affection', '/studio/inbox', '/studio/memories']
        : ['/home', '/affection', '/inbox', '/memories'];
    final index = routes.indexOf(path).clamp(0, 3);
    final entries = studio ? null : ref.watch(inboxProvider).value;
    final unread = entries?.where((e) => e.openedAt == null).length ?? 0;
    if (!studio) {
      ref.listen(inboxProvider, (old, next) {
        if (old?.hasValue == true &&
            next.hasValue &&
            ref.read(settingsProvider).notifications) {
          final ids = old!.value!.map((e) => e.id).toSet();
          if (next.value!.any(
            (e) => e.openedAt == null && !ids.contains(e.id),
          )) {
            notify(context, 'Your bear sent a little surprise ♡');
          }
        }
      });
    }
    final wide = MediaQuery.sizeOf(context).width >= 960;
    const icons = [
      Icons.cottage_outlined,
      Icons.favorite_border_rounded,
      Icons.mail_outline_rounded,
      Icons.auto_stories_outlined,
    ];
    const labels = ['Our world', 'Send love', 'Surprises', 'Memories'];
    Widget navIcon(int i) => i == 2 && unread > 0
        ? Badge(label: Text('$unread'), child: Icon(icons[i]))
        : Icon(icons[i]);
    final content = Column(
      children: [
        if (studio)
          Material(
            color: const Color(0xFFEADFEF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_outlined, size: 14),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'LOCAL PREVIEW · Explore your little world',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => context.go('/welcome'),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        'Connect ›',
                        style: TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (wide)
              Container(
                width: 232,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFEADFD6))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 36, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Palette.pink,
                            size: 28,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'bear with me',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'a little world, just for us.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          selected: index == i,
                          selectedTileColor: Palette.cream,
                          selectedColor: Palette.ink,
                          leading: navIcon(i),
                          title: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: index == i
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          onTap: () => context.go(routes[i]),
                        ),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: PaperCard(
                        color: Palette.cream,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 17,
                              color: Palette.muted,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Made for two.\nOnly two.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              studio
                                  ? 'Your story starts here.'
                                  : 'Your own corner of the world.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      child: ListTile(
                        leading: const Icon(Icons.tune_rounded, size: 20),
                        title: const Text(
                          'Our settings',
                          style: TextStyle(fontSize: 13),
                        ),
                        onTap: () => context.push(
                          studio ? '/studio/settings' : '/settings',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: content),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(routes[i]),
              destinations: List.generate(
                4,
                (i) =>
                    NavigationDestination(icon: navIcon(i), label: labels[i]),
              ),
            ),
    );
  }
}
