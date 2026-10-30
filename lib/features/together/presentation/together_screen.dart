import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/domain/affection_type.dart';
import '../../affection/domain/models.dart';
import '../../animation/presentation/bear_scene.dart';
import '../../settings/data/settings_repository.dart';
import '../data/live_session_repository.dart';

final liveSessionProvider = StreamProvider.autoDispose<LiveInteractionSession?>(
  (ref) {
    final repo = ref.watch(affectionRepositoryProvider);
    return repo == null
        ? Stream.value(null)
        : LiveSessionRepository(repo).watch();
  },
);

class TogetherScreen extends ConsumerStatefulWidget {
  const TogetherScreen({super.key});
  @override
  ConsumerState<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends ConsumerState<TogetherScreen> {
  bool _busy = false;
  Object? _error;
  Future<void> _run(Future<void> Function() work) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveSessionProvider),
        settings = ref.watch(settingsProvider);
    final session = state.value, repo = ref.watch(affectionRepositoryProvider);
    final api = repo == null ? null : LiveSessionRepository(repo);
    final action = AffectionType.values
        .where((t) => t.name == session?.action)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'A little time together',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Eyebrow('Right here, right now'),
              const SizedBox(height: 16),
              const Text(
                'Same little moment.',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1.15,
                child: BearScene(
                  key: ValueKey(session?.sequence),
                  action: session?.status == 'active' ? action : null,
                  reducedMotion:
                      settings.reducedMotion ||
                      MediaQuery.disableAnimationsOf(context),
                ),
              ),
              const SizedBox(height: 22),
              if (state.isLoading)
                const CircularProgressIndicator(strokeWidth: 2),
              if (state.hasError)
                ErrorNotice(
                  state.error!,
                  retry: () => ref.invalidate(liveSessionProvider),
                ),
              if (_error != null) ErrorNotice(_error!),
              if (session == null || session.status == 'ended')
                PrimaryButton(
                  label: 'Invite my bear to join',
                  busy: _busy,
                  icon: Icons.people_outline_rounded,
                  onPressed: api == null ? null : () => _run(api.invite),
                ),
              if (session?.status == 'invited') ...[
                Text(
                  session!.initiatorUid == repo?.uid
                      ? 'Waiting for your bear to join…'
                      : 'Your bear saved a little seat for you.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                if (session.initiatorUid != repo?.uid)
                  PrimaryButton(
                    label: 'I’m here, bear',
                    busy: _busy,
                    onPressed: () =>
                        _run(() => api!.status(session.id, 'active')),
                  ),
              ],
              if (session?.status == 'active') ...[
                const Text(
                  'You’re sharing this room. ♡',
                  style: TextStyle(
                    color: Palette.rose,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in [
                      AffectionType.holdingHands,
                      AffectionType.warmHug,
                      AffectionType.happyDance,
                      AffectionType.cuddleTime,
                    ])
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () =>
                                  _run(() => api!.action(session!.id, t.name)),
                        child: Text(t.title),
                      ),
                  ],
                ),
              ],
              if (session != null && session.status != 'ended')
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => api!.status(session.id, 'ended')),
                    child: const Text('Close our little room'),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Both bears need to keep the app open and connected.\nScenes follow shared actions; their timing may vary a little.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Palette.muted,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
