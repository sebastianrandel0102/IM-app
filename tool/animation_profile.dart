import 'dart:convert';

import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/animation/presentation/bear_scene.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Local-only frame timing harness. No Firebase, accounts or delivery calls.
// flutter run --profile -t tool/animation_profile.dart -d chrome
// Use an Android device for representative native GPU/60 Hz acceptance.
void main() =>
    runApp(MaterialApp(theme: buildTheme(), home: const AnimationProfile()));

class AnimationProfile extends StatefulWidget {
  const AnimationProfile({super.key});
  @override
  State<AnimationProfile> createState() => _AnimationProfileState();
}

class _AnimationProfileState extends State<AnimationProfile> {
  final _build = <int>[], _raster = <int>[], _total = <int>[];
  int _index = 0;
  bool _finished = false;
  String _report = '';
  final _watch = Stopwatch();
  final _completed = <String>[];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
    _watch.start();
  }

  void _timings(List<FrameTiming> timings) {
    if (_finished) return;
    for (final timing in timings) {
      _build.add(timing.buildDuration.inMicroseconds);
      _raster.add(timing.rasterDuration.inMicroseconds);
      _total.add(timing.totalSpan.inMicroseconds);
    }
  }

  double _percentile(List<int> source, double p) {
    if (source.isEmpty) return 0;
    final sorted = [...source]..sort();
    return sorted[((sorted.length - 1) * p).round()] / 1000;
  }

  void _next() {
    final action = AffectionType.values[_index % AffectionType.values.length];
    final sender = BearCharacter.values[_index ~/ AffectionType.values.length];
    _completed.add('${action.name}:${sender.name}');
    if (_index + 1 <
        AffectionType.values.length * BearCharacter.values.length) {
      setState(() => _index++);
      return;
    }
    // FrameTiming is batched by the engine. Wait for its trailing batch before
    // finalizing; this delay does not drive any part of the character rig.
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _watch.stop();
      final result = {
        'target': kIsWeb ? 'web-profile' : defaultTargetPlatform.name,
        'profileMode': kProfileMode,
        'completed': _completed,
        'elapsedSeconds': _watch.elapsedMilliseconds / 1000,
        'frameTimingSamples': _total.length,
        'buildP95Ms': _percentile(_build, .95),
        'rasterP95Ms': _percentile(_raster, .95),
        'totalP95Ms': _percentile(_total, .95),
        'framesOver16_667Ms': _total.where((v) => v > 16667).length,
        'note':
            'Observed harness timings only; web is not Android GPU acceptance.',
      };
      setState(() {
        _finished = true;
        _report = const JsonEncoder.withIndent('  ').convert(result);
      });
      debugPrint(
        'ANIMATION_PROFILE_RESULT ${jsonEncode(result)}',
        wrapWidth: 10000,
      );
    });
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Local animation profile')),
    body: Center(
      child: SizedBox(
        width: 430,
        child: _finished
            ? SingleChildScrollView(child: SelectableText(_report))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_index + 1} / 48 · ${AffectionType.values[_index % 24].title}',
                  ),
                  AspectRatio(
                    aspectRatio: 400 / 340,
                    child: BearScene(
                      key: ValueKey(_index),
                      action: AffectionType.values[_index % 24],
                      sender: BearCharacter.values[_index ~/ 24],
                      onComplete: _next,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
