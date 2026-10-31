import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/domain/affection_type.dart';
import '../../animation/presentation/bear_scene.dart';
import '../../settings/data/settings_repository.dart';

class StudioController extends Notifier<SceneTheme> {
  @override
  SceneTheme build() => SceneTheme.cozyRoom;
  void select(SceneTheme theme) => state = theme;
}

final studioThemeProvider = NotifierProvider<StudioController, SceneTheme>(
  StudioController.new,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.studio = false});
  final bool studio;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final profile = studio ? null : ref.watch(currentProfileProvider).value;
    final partner = studio ? null : ref.watch(partnerProvider).value;
    final pair = studio ? null : ref.watch(pairProvider).value;
    final world = studio ? null : ref.watch(worldProvider).value;
    final user = studio ? null : ref.watch(authProvider).value;
    final inbox = studio ? null : ref.watch(inboxProvider);
    final unread = inbox?.value?.where((e) => e.openedAt == null).length ?? 0;
    final theme = studio
        ? ref.watch(studioThemeProvider)
        : SceneTheme.values.firstWhere(
            (t) => t.name == world?['themeId'],
            orElse: () => SceneTheme.cozyRoom,
          );
    void affection([AffectionType? type]) => context.go(
      studio
          ? (type == null
                ? '/studio/affection'
                : '/studio/preview?type=${type.name}')
          : (type == null
                ? '/affection'
                : '/affection/preview?type=${type.name}'),
    );
    final room = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 1.17,
            child: BearScene(
              theme: theme,
              interactive: true,
              intensity: settings.animationIntensity,
              onLocalReaction: (_) {
                if (settings.haptics) HapticFeedback.selectionClick();
              },
              reducedMotion:
                  settings.reducedMotion ||
                  MediaQuery.disableAnimationsOf(context),
              accessory: profile?.accessory ?? 'none',
              sender: user != null && pair != null
                  ? pair.bearFor(user.uid)
                  : BearCharacter.brown,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Tap a nose, stroke a head, or hold a paw.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Palette.muted),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Palette.sage,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              theme.label,
              style: const TextStyle(fontSize: 12, color: Palette.muted),
            ),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(color: Palette.muted)),
            TextButton(
              onPressed: () =>
                  context.push(studio ? '/studio/settings' : '/customize'),
              child: const Text(
                'Make it yours',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaperCard(
          color: const Color(0xFFF2E6EC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    color: Palette.rose,
                    size: 20,
                  ),
                  Spacer(),
                  Eyebrow('Sealed with love'),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                unread > 0
                    ? 'A little love\nhas arrived.'
                    : 'Good things come\nin little envelopes.',
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                unread > 0
                    ? '$unread ${unread == 1 ? 'surprise is' : 'surprises are'} waiting for your curious paws.'
                    : 'Your surprises stay a secret until you’re ready to open them.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Palette.muted,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      context.go(studio ? '/studio/inbox' : '/inbox'),
                  child: Text(
                    unread > 0 ? 'Open my inbox  ›' : 'Peek at my inbox  ›',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PaperCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: Palette.caramel,
                size: 23,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('A little reminder', color: Palette.muted),
                    const SizedBox(height: 9),
                    const Text(
                      '“Distance is just a reason\nto love a little louder.”',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      studio
                          ? 'Your little story starts with a hello.'
                          : 'Thinking of ${partner?.displayName ?? 'your favorite bear'}?',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
      child: PageBody(
        maxWidth: 1060,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Eyebrow('Our little world'),
                const Spacer(),
                IconButton(
                  tooltip: 'Our settings',
                  onPressed: () =>
                      context.push(studio ? '/studio/settings' : '/settings'),
                  icon: const Icon(Icons.tune_rounded, size: 21),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 12,
              children: [
                Text(
                  studio
                      ? 'Home is a little closer.'
                      : 'Hi, ${profile?.displayName ?? 'little bear'}.',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.paper,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Palette.pink,
                        size: 12,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        studio
                            ? 'you + your person'
                            : '${profile?.displayName ?? 'You'} + ${partner?.displayName ?? 'your bear'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Different places. The same little world.',
              style: TextStyle(color: Palette.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            if (inbox?.hasError == true) ...[
              ErrorNotice(
                inbox!.error!,
                retry: () => ref.invalidate(inboxProvider),
              ),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, c) => c.maxWidth > 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: room),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: side),
                      ],
                    )
                  : Column(children: [room, const SizedBox(height: 15), side]),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Little gestures, big feelings'),
                      SizedBox(height: 7),
                      Text(
                        'What does love look like today?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => affection(),
                  child: const Text(
                    'See all  ›',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth > 700 ? 4 : 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final type in [
                      AffectionType.warmHug,
                      AffectionType.cheekKiss,
                      AffectionType.holdingHands,
                      AffectionType.iMissYou,
                    ])
                      SizedBox(
                        width: (c.maxWidth - 12 * (columns - 1)) / columns,
                        child: QuickAffectionCard(
                          type: type,
                          onTap: () => affection(type),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 27),
            Center(
              child: Text(
                'a little love goes a long way. ♡',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.muted.withValues(alpha: .8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAffectionCard extends StatelessWidget {
  const QuickAffectionCard({
    super.key,
    required this.type,
    required this.onTap,
  });
  final AffectionType type;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Palette.paper,
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: type.scene == 'moon'
                    ? Palette.lavender
                    : Palette.blush.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                affectionIcon(type.scene),
                size: 22,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              type.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              type == AffectionType.warmHug
                  ? 'An armful of you.'
                  : type == AffectionType.cheekKiss
                  ? 'A tiny, happy blush.'
                  : type == AffectionType.holdingHands
                  ? 'Never too far apart.'
                  : 'Until I see you again.',
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ),
      ),
    ),
  );
}
