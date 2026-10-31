import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/components.dart';
import '../../affection/data/affection_repository.dart';
import '../../affection/domain/affection_type.dart';
import '../../affection/domain/models.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/gesture_definition.dart';
import 'bear_scene.dart';
import 'bear_choreography.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    this.id,
    this.payload,
    this.studio = false,
    this.typeName,
  });
  final String? id, typeName;
  final ProtectedMomentPayload? payload;
  final bool studio;
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  ProtectedMomentPayload? _payload;
  Object? _error;
  final _audio = AudioPlayer();
  bool _holding = false,
      _complete = false,
      _saved = false,
      _stopped = false,
      _loading = true;
  bool _markedComplete = false, _markingComplete = false;
  int _taps = 0, _replay = 0;
  double _walk = 0;
  bool _inputReady = false;
  bool _sceneReady = false;
  final Set<BearSceneControl> _sceneControls = {};
  Duration? _lastTap;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.studio) {
        _payload = ProtectedMomentPayload(
          momentId: 'local-preview',
          type: AffectionType.values.firstWhere(
            (e) => e.name == widget.typeName,
            orElse: () => AffectionType.warmHug,
          ),
          variant: 'gentle',
          personalMessage: '',
          senderBear: BearCharacter.brown,
          receiverBear: BearCharacter.white,
        );
      } else if (widget.payload != null) {
        _payload = widget.payload;
      } else {
        final repo = ref.read(affectionRepositoryProvider)!;
        try {
          _payload = await repo.readOpened(widget.id!);
        } catch (e) {
          _payload = repo.cachedOpened(widget.id!);
          if (_payload == null) rethrow;
        }
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _finish() async {
    if (!mounted || _holding) return;
    setState(() => _complete = true);
    if (widget.studio || _markedComplete || _markingComplete) return;
    _markingComplete = true;
    try {
      await ref
          .read(affectionRepositoryProvider)!
          .complete(widget.id ?? _payload!.momentId);
      _markedComplete = true;
    } catch (_) {
      if (mounted) {
        notify(
          context,
          'This moment played. Its playback status will update when you retry online.',
        );
      }
    } finally {
      _markingComplete = false;
    }
  }

  void _contact() {
    if (!mounted || !ref.read(settingsProvider).haptics) return;
    if (_payload?.type == AffectionType.highFive) {
      HapticFeedback.lightImpact();
    } else if ([
      'kiss',
      'hug',
      'cuddle',
      'boop',
      'pat',
    ].contains(_payload?.type.scene)) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _tap() async {
    if (_holding || !_inputReady) return;
    final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    if (_lastTap != null && (now - _lastTap!).inMilliseconds < 250) return;
    _lastTap = now;
    setState(() {
      _taps++;
      _stopped = false;
      // Consume readiness synchronously. A second pointer event can arrive
      // before the scene's next frame publishes its new approach state.
      if (BearGestureDefinition.of(_payload!.type).repeatFrom != null) {
        _inputReady = false;
      }
    });
    final settings = ref.read(settingsProvider);
    if (settings.sound) {
      try {
        await _audio.setVolume(.18);
        if (!mounted) return;
        await _audio.play(AssetSource('audio/heart.wav'));
      } catch (_) {
        /* Silent playback remains fully usable. */
      }
    }
  }

  void _hold(bool holding) {
    if (_holding == holding) return;
    setState(() {
      _holding = holding;
      _stopped = false;
      if (holding) _complete = false;
    });
  }

  void _replayMoment() {
    setState(() {
      _replay++;
      _complete = false;
      _stopped = false;
      _taps = 0;
      _walk = 0;
      _holding = false;
      _sceneReady = false;
      _sceneControls.clear();
      _inputReady = false;
    });
    _lastTap = null;
    _audio.stop();
  }

  Future<void> _save() async {
    try {
      await MemoryRepository(ref.read(affectionRepositoryProvider)!)
          .save(_payload!);
      if (mounted) {
        setState(() => _saved = true);
        notify(context, 'Tucked into your memory book. ♡');
      }
    } catch (e) {
      if (mounted) notify(context, friendlyError(e));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _audio.stop();
      // The platform may cancel the pointer while backgrounded without sending
      // a long-press end. Do not resume with an unintentionally latched hug.
      if (_holding) _hold(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final payload = _payload;
    final hiddenNote = [
      'heart',
      'moon',
      'flower',
      'gift',
    ].contains(payload?.type.scene);
    final hug = BearChoreography.canHold(payload?.type);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.studio ? 'A little local moment' : 'Just for you',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: PageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(70),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (payload == null) ...[
                ErrorNotice(_error ?? 'This moment could not load.'),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Try again',
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                ),
              ] else ...[
                Eyebrow(
                  widget.studio
                      ? 'Local animation preview'
                      : payload.type.category,
                ),
                const SizedBox(height: 14),
                Text(
                  payload.type.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tap,
                  onLongPressStart: hug ? (_) => _hold(true) : null,
                  onLongPressEnd: hug ? (_) => _hold(false) : null,
                  onLongPressCancel: hug ? () => _hold(false) : null,
                  onHorizontalDragUpdate: (d) {
                    if (_inputReady &&
                        [
                          AffectionType.holdingHands,
                          AffectionType.piggybackRide,
                        ].contains(payload.type)) {
                      setState(
                        () => _walk = (_walk + d.delta.dx * .2).clamp(-25, 25),
                      );
                    }
                  },
                  onHorizontalDragEnd:
                      payload.type == AffectionType.sleepTogether
                      ? (_) => setState(() => _stopped = true)
                      : null,
                  child: AspectRatio(
                    aspectRatio: 1.05,
                    child: BearScene(
                      key: ValueKey(_replay),
                      action: payload.type,
                      variant: payload.variant,
                      sender: payload.senderBear,
                      reducedMotion:
                          settings.reducedMotion ||
                          MediaQuery.disableAnimationsOf(context),
                      holding: _holding,
                      taps: _taps,
                      walk: _walk,
                      stopped: _stopped,
                      controls: _sceneControls,
                      onComplete: _finish,
                      onContact: _contact,
                      onEvent: (event) {
                        if (mounted &&
                            event == BearAnimationEvent.contactStarted) {
                          setState(() => _sceneReady = true);
                        }
                      },
                      onInputReadyChanged: (ready) {
                        if (mounted && ready != _inputReady) {
                          setState(() => _inputReady = ready);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.paper,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 17,
                        color: Palette.rose,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _holding
                              ? 'As long as you need. ♡'
                              : payload.type.gesture,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if ([
                  AffectionType.comfortHug,
                  AffectionType.cuddleTime,
                  AffectionType.sleepTogether,
                ].contains(payload.type))
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final (control, label) in switch (payload.type) {
                        AffectionType.comfortHug => [
                          (BearSceneControl.headPat, 'Pat my head'),
                          (BearSceneControl.stayBeside, 'Stay beside me'),
                        ],
                        AffectionType.cuddleTime => [
                          (BearSceneControl.blanket, 'Cover with blanket'),
                          (BearSceneControl.lamp, 'Turn off lamp'),
                          (BearSceneControl.closer, 'Move closer'),
                        ],
                        _ => [
                          (BearSceneControl.closer, 'Move closer'),
                          (BearSceneControl.holdHands, 'Hold paws'),
                        ],
                      })
                        FilterChip(
                          label: Text(label),
                          selected: _sceneControls.contains(control),
                          onSelected: !_sceneReady || _stopped
                              ? null
                              : (value) => setState(() {
                                  if (value) {
                                    _sceneControls.add(control);
                                  } else {
                                    _sceneControls.remove(control);
                                  }
                                }),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (hug)
                      OutlinedButton.icon(
                        onPressed: () => _hold(!_holding),
                        icon: Icon(
                          _holding
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                        ),
                        label: Text(
                          _holding ? 'Let go gently' : 'Stay in this hug',
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _inputReady ? _tap : null,
                        icon: Icon(affectionIcon(payload.type.scene), size: 17),
                        label: Text(switch (payload.type.scene) {
                          'kiss' => 'Kiss back',
                          'flower' => 'Bloom for me',
                          'sleep' => 'A little cozier',
                          'rain' => 'Come closer',
                          'gift' => 'Unwrap it',
                          'moon' || 'heart' => 'Read my note',
                          _ => 'One more time',
                        }),
                      ),
                    if ([
                      AffectionType.holdingHands,
                      AffectionType.piggybackRide,
                    ].contains(payload.type)) ...[
                      IconButton(
                        onPressed: !_inputReady
                            ? null
                            : () => setState(
                                () => _walk = (_walk - 10).clamp(-25, 25),
                              ),
                        tooltip: 'Walk left',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      IconButton(
                        onPressed: !_inputReady
                            ? null
                            : () => setState(
                                () => _walk = (_walk + 10).clamp(-25, 25),
                              ),
                        tooltip: 'Walk right',
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                    if (payload.type == AffectionType.playfulTickle)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          setState(() {
                            _stopped = true;
                            _holding = false;
                          });
                          _audio.stop();
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop'),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                if (!hiddenNote || _taps > 0)
                  PaperCard(
                    color: const Color(0xFFF1E4EA),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Palette.rose,
                          size: 22,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          payload.personalMessage.isEmpty
                              ? payload.type.message
                              : payload.personalMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'A little note is waiting in the scene. ♡',
                    style: TextStyle(color: Palette.muted, fontSize: 12),
                  ),
                const SizedBox(height: 24),
                if (_complete && !widget.studio)
                  PrimaryButton(
                    label: _saved
                        ? 'Safe in your memories'
                        : 'Keep this little memory',
                    icon: _saved
                        ? Icons.check_rounded
                        : Icons.auto_stories_outlined,
                    onPressed: _saved ? null : _save,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _replayMoment,
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text('One more time'),
                      ),
                    ),
                    if (!widget.studio) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/affection'),
                          icon: const Icon(
                            Icons.favorite_border_rounded,
                            size: 18,
                          ),
                          label: const Text('Send love back'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.studio) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Local preview · Flutter vector animation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Palette.muted,
                      height: 1.7,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
