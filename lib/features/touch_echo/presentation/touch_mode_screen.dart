import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/domain/affection_type.dart';
import '../../settings/data/settings_repository.dart';
import '../data/touch_echo_repository.dart';
import '../domain/touch_intent.dart';
import 'touch_stage.dart';
import 'touch_haptics.dart';

class TouchModeScreen extends ConsumerStatefulWidget {
  const TouchModeScreen({super.key, this.studio = false, this.replyTo});
  final bool studio;
  final String? replyTo;
  @override
  ConsumerState<TouchModeScreen> createState() => _TouchModeScreenState();
}

class _TouchModeScreenState extends ConsumerState<TouchModeScreen> {
  TouchIntent? _intent;
  String? _requestId, _message;
  bool _preview = false, _guides = false, _heart = false;
  int _replay = 0;
  void _recognized(TouchResult result) {
    if (!mounted) return;
    setState(() {
      if (result.intent != null) {
        _intent = result.intent;
        _requestId = null;
        _preview = false;
      }
      _message = result.message;
    });
    if (result.intent != null) {
      touchHaptic(ref.read(settingsProvider), result.intent!.style);
    }
  }

  void _retryTouch() {
    setState(() {
      _preview = false;
      _intent = null;
      _requestId = null;
      _message = null;
      _replay++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final repo = widget.studio ? null : ref.watch(touchEchoRepositoryProvider);
    final pair = widget.studio ? null : ref.watch(pairProvider).value;
    final user = widget.studio ? null : ref.watch(authProvider).value;
    final partner = widget.studio ? null : ref.watch(partnerProvider).value;
    final bear = pair != null && user != null
        ? pair.bearFor(user.uid)
        : BearCharacter.brown;
    final receive = widget.studio
        ? true
        : ref.watch(receiveTouchesProvider).value ?? true;
    Widget body() => Builder(
      builder: (context) {
        final pending = repo?.state == TouchFlowState.sendPending;
        final failed = repo?.state == TouchFlowState.failed;
        final sent =
            repo?.state == TouchFlowState.sent && repo?.pendingId == _requestId;
        final intent = _intent ?? repo?.pendingIntent;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PageBody(
            maxWidth: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Eyebrow('Send your actual touch'),
                const SizedBox(height: 10),
                Text(
                  _preview ? 'A little preview.' : 'Touch your bear gently.',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.replyTo != null
                      ? 'Touch Back · a new touch linked to the Echo you opened.'
                      : 'Pet, tap, rub, or hold. A little affection, made by you.',
                  style: const TextStyle(color: Palette.muted, height: 1.5),
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 400 / 340,
                  child: TouchStage(
                    key: ValueKey('$_preview-$_replay-$pending'),
                    bear: bear,
                    intent: _preview ? intent : null,
                    onResult: pending || sent || failed ? null : _recognized,
                    reducedMotion: settings.reducedMotion,
                    guides: _guides,
                    heartMode: _heart,
                    sensitivity: settings.touchSensitivity,
                    motionScale: settings.animationIntensity,
                  ),
                ),
                const SizedBox(height: 12),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.muted),
                  ),
                if (pending || failed || sent) ...[
                  Semantics(
                    liveRegion: true,
                    child: PaperCard(
                      child: Column(
                        children: [
                          Icon(
                            sent
                                ? Icons.check_circle_outline
                                : pending
                                ? Icons.schedule
                                : Icons.cloud_off_outlined,
                            color: Palette.rose,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sent
                                ? 'Delivered to your private inbox'
                                : pending
                                ? 'Pending · waiting for database confirmation'
                                : 'This touch could not be sent',
                            textAlign: TextAlign.center,
                          ),
                          if (pending)
                            const Text(
                              'Your touch is saved on this device. It will retry while you are signed in to this pair.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Palette.muted,
                              ),
                            ),
                          if (repo?.error != null)
                            Text(
                              friendlyError(repo!.error!),
                              textAlign: TextAlign.center,
                            ),
                          if (!sent)
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: repo!.retry,
                                  child: const Text('Retry delivery'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    try {
                                      await repo.discard();
                                      if (mounted) _retryTouch();
                                    } catch (e) {
                                      if (context.mounted) {
                                        notify(context, friendlyError(e));
                                      }
                                    }
                                  },
                                  child: const Text('Cancel pending touch'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (intent != null && !pending && !failed && !sent) ...[
                  PaperCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          intent.kind.title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(intent.durationMs / 1000).toStringAsFixed(1)} seconds · for ${partner?.displayName ?? 'your partner'}',
                          style: const TextStyle(color: Palette.muted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final style in TouchStyle.values)
                              ChoiceChip(
                                label: Text(style.name),
                                selected: intent.style == style,
                                onSelected: (_) => setState(() {
                                  _intent = intent.withStyle(style);
                                  _requestId = null;
                                  _replay++;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!_preview)
                          FilledButton.icon(
                            onPressed: () => setState(() {
                              _preview = true;
                              _replay++;
                            }),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Preview this touch'),
                          )
                        else ...[
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _replay++),
                            icon: const Icon(Icons.replay),
                            label: const Text('Replay preview'),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: widget.studio || repo == null
                                ? null
                                : () async {
                                    _requestId ??= repo.newId();
                                    try {
                                      await repo.submit(
                                        _requestId!,
                                        intent,
                                        replyTo: widget.replyTo,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        notify(context, friendlyError(e));
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.favorite_border),
                            label: const Text('Send This Touch'),
                          ),
                          if (widget.studio)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Local preview. Sign in and pair to send through Firebase.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                        TextButton(
                          onPressed: _retryTouch,
                          child: const Text('Retry / Cancel preview'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sent)
                  FilledButton(
                    onPressed: _retryTouch,
                    child: const Text('Make another touch'),
                  ),
                if (!_preview && !pending && !failed && !sent) ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Show gentle hints'),
                        selected: _guides,
                        onSelected: (v) => setState(() => _guides = v),
                      ),
                      FilterChip(
                        label: const Text('Draw a Heart'),
                        selected: _heart,
                        onSelected: (v) => setState(() => _heart = v),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Touch actions'),
                    subtitle: const Text(
                      'Accessible alternatives and touch guidance',
                    ),
                    children: [
                      for (final kind in TouchKind.values)
                        ListTile(
                          title: Text(kind.title),
                          subtitle: Text(kind.hint),
                          trailing: const Icon(Icons.favorite_border, size: 20),
                          onTap: () => _recognized(
                            TouchResult(
                              TouchResultKind.recognized,
                              intent: TouchIntent(
                                kind: kind,
                                style: TouchStyle.gentle,
                                intensity: .3,
                                durationMs: 1800,
                                seed: 17,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Touch sensitivity',
                    style: TextStyle(fontSize: 12),
                  ),
                  Slider(
                    value: settings.touchSensitivity,
                    min: .7,
                    max: 1.4,
                    divisions: 7,
                    label: settings.touchSensitivity.toStringAsFixed(1),
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(settings.copyWith(touchSensitivity: v)),
                  ),
                ],
                if (!widget.studio)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Receive Touch Echoes'),
                    subtitle: const Text(
                      'Pause new touches whenever you need.',
                    ),
                    value: receive,
                    onChanged: repo == null
                        ? null
                        : (v) async {
                            try {
                              await repo.receiveTouches(v);
                            } catch (e) {
                              if (context.mounted) {
                                notify(context, friendlyError(e));
                              }
                            }
                          },
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Your partner chooses when to open. Finger paths stay on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Palette.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Touch Echo'),
        leading: IconButton(
          tooltip: 'Exit Touch Mode',
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(widget.studio ? '/studio' : '/home'),
        ),
      ),
      body: repo == null
          ? body()
          : ListenableBuilder(listenable: repo, builder: (_, _) => body()),
    );
  }
}
