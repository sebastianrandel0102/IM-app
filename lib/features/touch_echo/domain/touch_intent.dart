import '../../affection/domain/affection_type.dart';

enum TouchZone { head, nose, cheek, paw, belly, ear, chest, back, heart }

enum TouchStyle { gentle, normal, playful }

enum TouchKind {
  headPet(
    'Gentle Head Pet',
    TouchZone.head,
    AffectionType.headPat,
    'Slowly stroke the top of the head',
  ),
  noseBoop(
    'Nose Boop',
    TouchZone.nose,
    AffectionType.noseBoop,
    'Briefly tap the little nose',
  ),
  cheekCaress(
    'Cheek Caress',
    TouchZone.cheek,
    AffectionType.cheekKiss,
    'Slowly stroke a cheek',
  ),
  pawHold(
    'Paw Hold',
    TouchZone.paw,
    AffectionType.holdingHands,
    'Hold a paw still for a moment',
  ),
  bellyRub(
    'Belly Rub',
    TouchZone.belly,
    AffectionType.playfulTickle,
    'Draw a small circle on the belly',
  ),
  earRub(
    'Ear Rub',
    TouchZone.ear,
    AffectionType.headPat,
    'Gently rub an ear back and forth',
  ),
  hugHold(
    'Hug Hold',
    TouchZone.chest,
    AffectionType.warmHug,
    'Hold the chest to open both arms',
  ),
  backComfort(
    'Back Comfort',
    TouchZone.back,
    AffectionType.comfortHug,
    'Slowly stroke the outer shoulder',
  ),
  heartTrace(
    'Heart Trace',
    TouchZone.heart,
    AffectionType.heartDelivery,
    'Choose Draw a Heart, then trace a heart',
  ),
  tinyTickle(
    'Tiny Tickle',
    TouchZone.belly,
    AffectionType.playfulTickle,
    'Make tiny quick strokes on the belly',
  );

  const TouchKind(this.title, this.zone, this.legacyType, this.hint);
  final String title, hint;
  final TouchZone zone;
  final AffectionType legacyType;
}

/// Only semantic parameters cross the network. No pointer IDs or raw paths.
/// V1 remains a replay contract when future choreography is added.
class TouchIntent {
  TouchIntent({
    required this.kind,
    required this.style,
    required this.intensity,
    required this.durationMs,
    required this.seed,
    this.direction = 1,
    this.repetitions = 1,
  }) {
    if (!intensity.isFinite ||
        intensity < .15 ||
        intensity > 1 ||
        durationMs < 350 ||
        durationMs > 6000 ||
        seed < 0 ||
        seed > 2147483647 ||
        !direction.isFinite ||
        direction.abs() > 1 ||
        repetitions < 1 ||
        repetitions > 3) {
      throw const FormatException('This touch needs to be recorded again.');
    }
  }
  final TouchKind kind;
  final TouchStyle style;
  final double intensity, direction;
  final int durationMs, seed, repetitions;
  String get animationId => 'touch_${kind.name}';
  int get animationVersion => 1;
  int get playbackMs =>
      ((2400 + durationMs) *
              switch (style) {
                TouchStyle.gentle => 1.08,
                TouchStyle.normal => 1.0,
                TouchStyle.playful => .90,
              })
          .round()
          .clamp(3200, 9100);
  TouchIntent withStyle(TouchStyle next) => TouchIntent(
    kind: kind,
    style: next,
    intensity: switch (next) {
      TouchStyle.gentle => .3,
      TouchStyle.normal => .55,
      TouchStyle.playful => .8,
    },
    durationMs: durationMs,
    seed: seed,
    direction: direction,
    repetitions: repetitions,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'kind': kind.name,
    'zone': kind.zone.name,
    'style': style.name,
    'intensity': intensity,
    'durationMs': durationMs,
    'seed': seed,
    'direction': direction,
    'repetitions': repetitions,
    'animationId': animationId,
    'animationVersion': animationVersion,
  };
  factory TouchIntent.fromJson(Map<String, dynamic> d) {
    const keys = {
      'schemaVersion',
      'kind',
      'zone',
      'style',
      'intensity',
      'durationMs',
      'seed',
      'direction',
      'repetitions',
      'animationId',
      'animationVersion',
    };
    if (d.keys.toSet().difference(keys).isNotEmpty ||
        d.length != keys.length ||
        d['schemaVersion'] != 1 ||
        d['animationVersion'] != 1 ||
        d['durationMs'] is! int ||
        d['seed'] is! int ||
        d['repetitions'] is! int ||
        d['intensity'] is! num ||
        d['direction'] is! num) {
      throw const FormatException('Update the app or record this touch again.');
    }
    final kind = TouchKind.values.where((e) => e.name == d['kind']).firstOrNull;
    final style = TouchStyle.values
        .where((e) => e.name == d['style'])
        .firstOrNull;
    if (kind == null ||
        style == null ||
        d['zone'] != kind.zone.name ||
        d['animationId'] != 'touch_${kind.name}') {
      throw const FormatException('This touch animation is not supported.');
    }
    return TouchIntent(
      kind: kind,
      style: style,
      intensity: (d['intensity'] as num).toDouble(),
      durationMs: d['durationMs'],
      seed: d['seed'],
      direction: (d['direction'] as num).toDouble(),
      repetitions: d['repetitions'],
    );
  }
}

enum TouchFlowState {
  idle,
  tracking,
  previewReady,
  previewing,
  sendPending,
  sent,
  failed,
  canceled,
}

enum TouchResultKind { recognized, ambiguous, invalid, canceled, unsupported }

class TouchResult {
  const TouchResult(this.result, {this.intent, this.message});
  final TouchResultKind result;
  final TouchIntent? intent;
  final String? message;
}
