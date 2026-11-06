import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_intent.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_stage.dart';
import 'package:flutter/material.dart';

// Local art/anchor review only. No Firebase or simulated inbox delivery.
void main() =>
    runApp(MaterialApp(theme: buildTheme(), home: const TouchReview()));

class TouchReview extends StatefulWidget {
  const TouchReview({super.key});
  @override
  State<TouchReview> createState() => _TouchReviewState();
}

class _TouchReviewState extends State<TouchReview> {
  TouchKind _kind = TouchKind.headPet;
  TouchStyle _style = TouchStyle.gentle;
  BearCharacter _bear = BearCharacter.brown;
  bool _reduced = false, _anchors = false, _scrub = false;
  double _progress = .5;
  int _replay = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Touch Echo · local art review')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 700,
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropdownButton<TouchKind>(
                    value: _kind,
                    items: [
                      for (final kind in TouchKind.values)
                        DropdownMenuItem(value: kind, child: Text(kind.title)),
                    ],
                    onChanged: (v) => setState(() {
                      _kind = v!;
                      _replay++;
                    }),
                  ),
                  DropdownButton<TouchStyle>(
                    value: _style,
                    items: [
                      for (final style in TouchStyle.values)
                        DropdownMenuItem(value: style, child: Text(style.name)),
                    ],
                    onChanged: (v) => setState(() {
                      _style = v!;
                      _replay++;
                    }),
                  ),
                  FilterChip(
                    label: Text('${_bear.name} sends'),
                    selected: _bear == BearCharacter.white,
                    onSelected: (_) => setState(() {
                      _bear = _bear.other;
                      _replay++;
                    }),
                  ),
                  FilterChip(
                    label: const Text('Reduced motion'),
                    selected: _reduced,
                    onSelected: (v) => setState(() => _reduced = v),
                  ),
                  FilterChip(
                    label: const Text('Anchors'),
                    selected: _anchors,
                    onSelected: (v) => setState(() => _anchors = v),
                  ),
                  FilterChip(
                    label: const Text('Scrub frame'),
                    selected: _scrub,
                    onSelected: (v) => setState(() => _scrub = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 400 / 340,
                child: TouchStage(
                  key: ValueKey('$_replay-$_scrub-${_scrub ? _progress : 0}'),
                  bear: _bear,
                  intent: TouchIntent(
                    kind: _kind,
                    style: _style,
                    intensity: .4,
                    durationMs: 1800,
                    seed: 123,
                  ),
                  initialProgress: _scrub ? _progress : 0,
                  reducedMotion: _reduced,
                  debugAnchors: _anchors,
                  frozen: _scrub,
                ),
              ),
              Slider(
                value: _progress,
                onChanged: (v) => setState(() => _progress = v),
              ),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _scrub = false;
                  _replay++;
                }),
                icon: const Icon(Icons.replay),
                label: const Text('Replay'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Inspect the forearm, paw contact, ear mark, facial clearance and settled frame at each checkpoint.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
