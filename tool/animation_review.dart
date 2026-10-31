import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/domain/gesture_definition.dart';
import 'package:bear_with_me/features/animation/presentation/bear_choreography.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Local-only animation workbench. No Firebase initialization or account access.
// flutter run -t tool/animation_review.dart -d chrome
void main() =>
    runApp(MaterialApp(theme: buildTheme(), home: const AnimationReview()));

class AnimationReview extends StatefulWidget {
  const AnimationReview({super.key});
  @override
  State<AnimationReview> createState() => _AnimationReviewState();
}

class _AnimationReviewState extends State<AnimationReview>
    with SingleTickerProviderStateMixin {
  AffectionType _action = AffectionType.warmHug;
  BearCharacter _sender = BearCharacter.brown;
  late BearPlayback _playback;
  late final Ticker _ticker;
  Duration? _last;
  double _speed = 1, _walk = 0;
  int _taps = 0;
  bool _playing = true, _hold = false, _reduced = false;
  String _variant = 'gentle';
  final _events = <BearAnimationEvent>[];
  BearPlayback _newPlayback() => BearPlayback(
    action: _action,
    reduced: _reduced,
    variant: _variant,
    onEvent: (event) {
      _events.add(event);
      if (_events.length > 4) _events.removeAt(0);
    },
  );
  @override
  void initState() {
    super.initState();
    _playback = _newPlayback();
    _ticker = createTicker((elapsed) {
      final before = _last;
      _last = elapsed;
      if (_playing && before != null) {
        _playback.advance((elapsed - before).inMicroseconds / 1e6 * _speed);
        setState(() {});
      }
    })..start();
  }

  void _configure() => _playback.configure(
    nextAction: _action,
    nextVariant: _variant,
    nextReduced: _reduced,
    nextHolding: _hold,
    nextStopped: false,
    nextTaps: _taps,
    nextWalk: _walk,
  );
  void _restart() {
    _playback.dispose();
    _playback = _newPlayback();
    _events.clear();
    _taps = 0;
    _hold = false;
    _walk = 0;
    _playing = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Animation review · local only')),
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                DropdownButton<AffectionType>(
                  value: _action,
                  isExpanded: true,
                  items: [
                    for (final a in AffectionType.values)
                      DropdownMenuItem(
                        value: a,
                        child: Text('${a.category} · ${a.title}'),
                      ),
                  ],
                  onChanged: (a) => setState(() {
                    _action = a!;
                    _restart();
                  }),
                ),
                DropdownButton<String>(
                  value: _variant,
                  items: [
                    for (final v in ['gentle', 'shy', 'playful'])
                      DropdownMenuItem(value: v, child: Text(v)),
                  ],
                  onChanged: (v) => setState(() {
                    _variant = v!;
                    _restart();
                  }),
                ),
                AspectRatio(
                  aspectRatio: 400 / 340,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: BearScenePainter(
                        t: _playback.progress,
                        action: _action,
                        sender: _sender,
                        theme: SceneTheme.cozyRoom,
                        holding: _hold,
                        taps: _taps,
                        walk: _walk,
                        reduced: _reduced,
                        accessory: 'none',
                        variant: _variant,
                        stopped: false,
                        playback: _playback,
                      ),
                    ),
                  ),
                ),
                Slider(
                  value: _playback.progress,
                  onChanged: (value) => setState(() {
                    _playing = false;
                    _playback.progress = value;
                    _playback.seconds =
                        value * _playback.duration.inMilliseconds / 1000;
                    _playback.completed = value == 1;
                  }),
                ),
                Text(
                  '${_playback.stage.name} · ${(_playback.progress * _playback.duration.inMilliseconds / 1000).toStringAsFixed(2)} s',
                ),
                Text(
                  _events.map((e) => e.name).join(' → '),
                  style: const TextStyle(fontSize: 11),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: _playing ? 'Pause' : 'Play',
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      onPressed: () => setState(() => _playing = !_playing),
                    ),
                    IconButton(
                      tooltip: 'Replay',
                      icon: const Icon(Icons.replay),
                      onPressed: () => setState(_restart),
                    ),
                    IconButton(
                      tooltip: 'Advance one frame (60 Hz)',
                      icon: const Icon(Icons.skip_next),
                      onPressed: () => setState(() {
                        _playing = false;
                        _playback.advance(1 / 60);
                      }),
                    ),
                    for (final speed in [.25, 1.0])
                      ChoiceChip(
                        label: Text('${speed}x'),
                        selected: _speed == speed,
                        onSelected: (_) => setState(() => _speed = speed),
                      ),
                    ChoiceChip(
                      label: Text('${_sender.name} sends'),
                      selected: _sender == BearCharacter.white,
                      onSelected: (_) =>
                          setState(() => _sender = _sender.other),
                    ),
                    FilterChip(
                      label: const Text('Reduced motion'),
                      selected: _reduced,
                      onSelected: (v) => setState(() {
                        _reduced = v;
                        _configure();
                      }),
                    ),
                    if (BearChoreography.canHold(_action))
                      FilterChip(
                        label: const Text('Hold'),
                        selected: _hold,
                        onSelected: (v) => setState(() {
                          _hold = v;
                          _configure();
                        }),
                      ),
                    OutlinedButton(
                      onPressed: !_playback.canReact
                          ? null
                          : () => setState(() {
                              _taps++;
                              _configure();
                            }),
                      child: const Text('Tap / react'),
                    ),
                  ],
                ),
                if ([
                  AffectionType.holdingHands,
                  AffectionType.piggybackRide,
                ].contains(_action))
                  Slider(
                    value: _walk,
                    min: -25,
                    max: 25,
                    label: 'Walk',
                    onChanged: (v) => setState(() {
                      _walk = v;
                      _configure();
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
