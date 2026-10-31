import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../../../app/theme/app_theme.dart';
import '../../affection/domain/affection_type.dart';
import '../domain/gesture_definition.dart';
import 'bear_choreography.dart';
import 'bear_vector_rig.dart';
import 'bear_physics.dart';
import 'bear_touch.dart';
import 'rive_bear_scene.dart';

/// Original vector artwork, with editable Flutter choreography, not a Rive rig.
class BearScene extends StatefulWidget {
  const BearScene({
    super.key,
    this.action,
    this.sender = BearCharacter.brown,
    this.theme = SceneTheme.cozyRoom,
    this.reducedMotion = false,
    this.holding = false,
    this.taps = 0,
    this.walk = 0,
    this.accessory = 'none',
    this.variant = 'gentle',
    this.stopped = false,
    this.onComplete,
    this.onContact,
    this.onInputReadyChanged,
    this.onEvent,
    this.controls = const {},
    this.intensity = 1,
    this.interactive = false,
    this.onLocalReaction,
    this.onLocalTap,
    this.initialElapsed = Duration.zero,
  });
  final AffectionType? action;
  final BearCharacter sender;
  final SceneTheme theme;
  final bool reducedMotion, holding, stopped;
  final int taps;
  final double walk;
  final String accessory, variant;
  final Set<BearSceneControl> controls;
  final double intensity;
  final bool interactive;
  final ValueChanged<BearReaction>? onLocalReaction;
  final VoidCallback? onLocalTap;
  final Duration initialElapsed;
  final VoidCallback? onComplete, onContact;
  final ValueChanged<bool>? onInputReadyChanged;
  final ValueChanged<BearAnimationEvent>? onEvent;
  @override
  State<BearScene> createState() => _BearSceneState();
}

class _BearSceneState extends State<BearScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BearPlayback _playback;
  late final Ticker _ticker;
  Duration? _lastTick;
  bool _foreground = true;
  bool? _lastReady;
  BearStroke? _stroke;
  Offset? _doubleTap;
  bool get _reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
  bool get _staticPreview =>
      _reduced && widget.onComplete == null && _playback.secondary.settled;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playback = BearPlayback(
      action: widget.action,
      variant: widget.variant,
      reduced: widget.reducedMotion,
      onComplete: () => widget.onComplete?.call(),
      onContact: () => widget.onContact?.call(),
      onEvent: (event) => widget.onEvent?.call(event),
    );
    if (widget.initialElapsed > Duration.zero && widget.action != null) {
      _playback.advance(widget.initialElapsed.inMicroseconds / 1e6);
    }
    _ticker = createTicker((elapsed) {
      final previous = _lastTick;
      _lastTick = elapsed;
      if (previous != null) {
        _playback.advance((elapsed - previous).inMicroseconds / 1e6);
      }
      final ready = _playback.canReact;
      if (_lastReady != ready) {
        _lastReady = ready;
        widget.onInputReadyChanged?.call(ready);
      }
      if ((widget.stopped || _reduced) &&
          (_playback.settled || _staticPreview)) {
        _syncTicker();
      }
    });
  }

  void _configure() {
    _playback.configure(
      nextAction: widget.action,
      nextVariant: widget.variant,
      nextReduced: _reduced,
      nextHolding: widget.holding,
      nextStopped: widget.stopped,
      nextTaps: widget.taps,
      nextWalk: widget.walk,
      nextControls: widget.controls,
      nextIntensity: widget.intensity,
    );
    if (_staticPreview) _playback.showPreview();
    _syncTicker();
  }

  void _syncTicker() {
    final enabled =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !_staticPreview &&
        !((widget.stopped || _reduced) && _playback.settled);
    if (enabled && !_ticker.isActive) {
      _lastTick = null;
      _ticker.start();
    }
    if (!enabled && _ticker.isActive) {
      _ticker.stop();
      _lastTick = null;
      _playback.secondary.suspend();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(BearScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stroke = null;
      _playback.secondary.suspend();
    }
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = Semantics(
      label: widget.action == null
          ? 'The caramel bear and white bear, together in a cozy little world'
          : '${widget.sender.name} bear and ${widget.sender.other.name} bear: ${widget.action!.title}',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: BearScenePainter(
            t: 0,
            action: widget.action,
            sender: widget.sender,
            theme: widget.theme,
            holding: widget.holding,
            taps: widget.taps,
            walk: widget.walk,
            reduced: _reduced,
            accessory: widget.accessory,
            variant: widget.variant,
            stopped: widget.stopped,
            playback: _playback,
          ),
          size: Size.infinite,
        ),
      ),
    );
    if (const bool.fromEnvironment('USE_AUTHORED_RIVE')) {
      return RiveBearScene(
        fallback: scene,
        action: widget.action,
        sender: widget.sender,
        holding: widget.holding,
        taps: widget.taps,
        reducedMotion: _reduced,
        variant: widget.variant,
      );
    }
    if (!widget.interactive) return scene;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        BearTouchHit? hit(Offset at) {
          final point = BearTouchGeometry.scenePoint(at, size);
          return point == null
              ? null
              : BearTouchGeometry.hit(_playback.frame, point);
        }

        void react(BearTouchHit target, BearReaction reaction) {
          if (reaction == BearReaction.pawHold) {
            _playback.holdPaw(target.left, near: target.near);
          } else {
            _playback.react(target.left, reaction);
          }
          widget.onLocalReaction?.call(reaction);
          _syncTicker();
        }

        return Semantics(
          hint: widget.action == AffectionType.sleepTogether
              ? 'Gently tap a bear for a sleepy response. Swipe to wake.'
              : 'Tap a head, nose, cheek or paw. Stroke the head or belly. Hold a paw. Double tap to jump.',
          customSemanticsActions: {
            const CustomSemanticsAction(label: 'Pet the first bear'): () =>
                react(
                  const BearTouchHit(true, BearTouchZone.head),
                  BearReaction.pet,
                ),
            const CustomSemanticsAction(label: 'Pet the second bear'): () =>
                react(
                  const BearTouchHit(false, BearTouchZone.head),
                  BearReaction.pet,
                ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              widget.onLocalTap?.call();
              final target = hit(d.localPosition);
              if (target == null) return;
              final reaction = widget.action == AffectionType.sleepTogether
                  ? BearReaction.sleepy
                  : switch (target.zone) {
                      BearTouchZone.head => BearReaction.curious,
                      BearTouchZone.nose => BearReaction.boop,
                      BearTouchZone.cheek => BearReaction.shy,
                      BearTouchZone.paw => BearReaction.wave,
                      BearTouchZone.belly => BearReaction.belly,
                      BearTouchZone.back => BearReaction.relax,
                    };
              react(target, reaction);
            },
            onDoubleTapDown: (d) => _doubleTap = d.localPosition,
            onDoubleTap: () {
              widget.onLocalTap?.call();
              final target = _doubleTap == null ? null : hit(_doubleTap!);
              if (target != null) {
                react(
                  target,
                  widget.action == AffectionType.sleepTogether
                      ? BearReaction.sleepy
                      : BearReaction.jump,
                );
              }
            },
            onLongPressStart: widget.action == null
                ? (d) {
                    final target = hit(d.localPosition);
                    if (target?.zone == BearTouchZone.paw) {
                      react(target!, BearReaction.pawHold);
                    }
                  }
                : null,
            onLongPressEnd: widget.action == null
                ? (_) => _playback.releaseTouch()
                : null,
            onLongPressCancel: widget.action == null
                ? _playback.releaseTouch
                : null,
            onPanStart: widget.action == null
                ? (d) {
                    final target = hit(d.localPosition);
                    final point = BearTouchGeometry.scenePoint(
                      d.localPosition,
                      size,
                    );
                    _stroke = target == null || point == null
                        ? null
                        : BearStroke(target, point);
                  }
                : null,
            onPanUpdate: widget.action == null
                ? (d) {
                    final point = BearTouchGeometry.scenePoint(
                      d.localPosition,
                      size,
                    );
                    if (point == null) return;
                    final reaction = _stroke?.move(hit(d.localPosition), point);
                    if (reaction != null) react(_stroke!.hit, reaction);
                  }
                : null,
            onPanEnd: widget.action == null ? (_) => _stroke = null : null,
            onPanCancel: widget.action == null ? () => _stroke = null : null,
            child: scene,
          ),
        );
      },
    );
  }
}

class BearScenePainter extends CustomPainter {
  BearScenePainter({
    required this.t,
    required this.action,
    required this.sender,
    required this.theme,
    required this.holding,
    required this.taps,
    required this.walk,
    required this.reduced,
    required this.accessory,
    required this.variant,
    required this.stopped,
    this.playback,
    this.showAnchors = false,
    this.showBounds = false,
  }) : super(repaint: playback);
  final double t, walk;
  final AffectionType? action;
  final BearCharacter sender;
  final SceneTheme theme;
  final bool holding, reduced, stopped;
  final int taps;
  final String accessory, variant;
  final BearPlayback? playback;
  final bool showAnchors, showBounds;
  double get clock => reduced || stopped ? 0 : playback?.seconds ?? t * 8;
  static const chocolate = Palette.outline;
  Paint fill(Color c) => Paint()..color = c;
  Paint stroke(Color c, [double width = 2.6]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void line(Canvas c, Offset a, Offset b, Color color, [double w = 2]) =>
      c.drawLine(a, b, stroke(color, w));
  void shape(Canvas c, Path p, Color color, [double w = 2.6]) {
    c.drawPath(p, fill(color));
    c.drawPath(p, stroke(chocolate, w));
  }

  void oval(Canvas c, Rect rect, Color color, {bool outlined = false}) {
    c.drawOval(rect, fill(color));
    if (outlined) c.drawOval(rect, stroke(chocolate));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    final scale = math.min(size.width / 400, size.height / 340);
    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 340 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 400, 340),
        const Radius.circular(28),
      ),
    );
    final frame =
        playback?.frame ??
        BearChoreography.sample(
          action: action,
          t: t,
          seconds:
              t *
              BearChoreography.duration(action, variant).inMilliseconds /
              1000,
          reduced: reduced,
          taps: taps,
          walk: walk,
          input: taps > 0 ? .7 : 1,
          stopped: stopped,
          variant: variant,
        );
    final night =
        [SceneTheme.moonlitNight, SceneTheme.starryBedroom].contains(theme) ||
        action == AffectionType.goodnightKiss ||
        action == AffectionType.sleepTogether ||
        action == AffectionType.iMissYou;
    final dim = night && frame.dim > .25;
    final bg = night
        ? const Color(0xFFE2D7EC)
        : theme == SceneTheme.pastelPinkRoom
        ? const Color(0xFFF6DFDF)
        : const Color(0xFFF2E5D9);
    canvas.drawColor(bg, BlendMode.srcOver);
    _room(canvas, night, dim);
    oval(
      canvas,
      const Rect.fromLTWH(62, 267, 276, 44),
      night ? const Color(0xFFB9A2BB) : const Color(0xFFE7CDC0),
    );
    oval(
      canvas,
      const Rect.fromLTWH(71, 270, 258, 35),
      night ? const Color(0xFFCCB9CF) : const Color(0xFFF2DED0),
    );
    final onBed = [
      AffectionType.cuddleTime,
      AffectionType.sleepTogether,
      AffectionType.goodnightKiss,
    ].contains(action);
    if (onBed) {
      _bed(canvas, night);
      _pillows(canvas);
    }
    if (action == AffectionType.comfortHug) {
      for (final x in [85.0, 305.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 288, 11, 17),
            const Radius.circular(3),
          ),
          fill(const Color(0xFFA77E69)),
        );
      }
      final back = RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 213, 248, 77),
        const Radius.circular(25),
      );
      canvas.drawRRect(back, fill(const Color(0xFFE2C9DD)));
      canvas.drawRRect(back, stroke(const Color(0xFF997E91), 2));
      line(
        canvas,
        const Offset(200, 228),
        const Offset(200, 273),
        const Color(0xFFC7A9C1),
        1.3,
      );
      for (final x in [68.0, 304.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 250, 28, 45),
            const Radius.circular(13),
          ),
          fill(const Color(0xFFD6BAD0)),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(76, 273, 248, 22),
          const Radius.circular(18),
        ),
        fill(const Color(0xFFD1B2C9)),
      );
    }
    for (final p in [frame.left, frame.right]) {
      final supported = onBed || action == AffectionType.comfortHug;
      oval(
        canvas,
        Rect.fromCenter(
          center: Offset(
            p.root.dx,
            supported
                ? p.root.dy + 2 + p.sit * 7 - p.recline * 12
                : 280 + p.sit * 8,
          ),
          width: (73 + p.recline * 30) / p.squash,
          height: (8 - p.recline * 3) * p.squash,
        ),
        const Color(0x27352320),
      );
    }
    canvas.save();
    final rightBehind =
        action == AffectionType.piggybackRide ||
        (action == AffectionType.spinningHug && math.sin(frame.spin) > 0);
    final actors = rightBehind
        ? [(frame.right, sender.other, 'none'), (frame.left, sender, accessory)]
        : [
            (frame.left, sender, accessory),
            (frame.right, sender.other, 'none'),
          ];
    // Each part is drawn once. Rear arms stay behind both torsos; front arms
    // cross the partner's torso while the head masks protect both faces.
    for (final (pose, bear, _) in actors) {
      BearVectorRig.arm(canvas, pose, bear, near: false);
    }
    for (final (pose, bear, item) in actors) {
      BearVectorRig.draw(canvas, pose, bear, item, head: false, arms: false);
    }
    for (final (pose, bear, item) in actors) {
      BearVectorRig.draw(canvas, pose, bear, item, body: false, arms: false);
    }
    for (final (pose, bear, _) in actors) {
      final partner = identical(pose, frame.left) ? frame.right : frame.left;
      final faceTouch =
          identical(pose, frame.left) &&
          ([
                AffectionType.headPat,
                AffectionType.noseBoop,
                AffectionType.wipeAwayTears,
                AffectionType.goodnightKiss,
              ].contains(action) ||
              (action == AffectionType.comfortHug &&
                  (playback?.interaction.pat ?? 0) > 0));
      BearVectorRig.arm(
        canvas,
        pose,
        bear,
        foreground: true,
        occluders: faceTouch ? const [] : [partner],
      );
    }
    if (action == AffectionType.blowingKisses) {
      final progress = playback?.progress ?? t;
      final lift = BearChoreography.window(progress, .15, .30, .38, .54);
      if (lift > .01) {
        canvas.drawCircle(
          BearVectorRig.paw(frame.left),
          6 * lift,
          fill(BearVectorRig.fur(sender)),
        );
        canvas.drawCircle(
          BearVectorRig.paw(frame.left),
          6 * lift,
          stroke(chocolate, 1.8),
        );
      }
    }
    canvas.restore();
    if (frame.blanket > .001) _blanket(canvas, frame);
    final prop = frame.prop.translate(
      0,
      reduced
          ? 0
          : (playback?.secondary.prop.position ?? 0) *
                (playback?.intensity ?? 1),
    );
    switch (action) {
      case AffectionType.flowerSurprise:
        if (frame.reveal > .01) {
          canvas.save();
          canvas.translate(prop.dx, prop.dy);
          canvas.scale(frame.reveal);
          canvas.rotate(math.sin(clock * 2) * .025 * frame.reveal);
          _flower(canvas, 0, 0, 1 + frame.bloom * .18 + frame.effect * .06);
          canvas.restore();
        }
      case AffectionType.heartDelivery:
      case AffectionType.shyConfession:
        _heart(
          canvas,
          prop.dx,
          prop.dy,
          (action == AffectionType.shyConfession ? 11 : 23) * frame.reveal,
          Palette.pink,
        );
      case AffectionType.surpriseBox:
        _giftAnimated(canvas, prop, frame.reveal);
      case AffectionType.blowingKisses:
        _heart(canvas, prop.dx, prop.dy, 10 * frame.reveal, Palette.pink);
      case AffectionType.underOneUmbrella:
        canvas.save();
        canvas.translate(prop.dx - 200, prop.dy - 95);
        canvas.translate(200, 218);
        canvas.rotate(frame.spin);
        canvas.translate(-200, -218);
        _umbrella(canvas);
        canvas.restore();
      case AffectionType.wipeAwayTears:
        oval(
          canvas,
          Rect.fromCenter(center: prop, width: 6, height: 10),
          const Color(0xFF9AC8D9).withValues(alpha: frame.tear),
        );
      case AffectionType.goodMorning:
        canvas.drawCircle(
          prop,
          18 * frame.reveal,
          fill(const Color(0xFFFFD9A0)),
        );
      default:
        break;
    }
    if (frame.effect > .01 && !reduced) {
      if ([
        AffectionType.highFive,
        AffectionType.surpriseBox,
        AffectionType.flowerSurprise,
      ].contains(action)) {
        for (var i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + .4;
          _spark(
            canvas,
            prop + Offset(math.cos(a), math.sin(a)) * (12 + 8 * frame.effect),
            3 * frame.effect,
            Palette.rose,
          );
        }
      } else {
        _heart(canvas, prop.dx, prop.dy, 8 * frame.effect, Palette.pink);
      }
    }
    if (action == null) {
      _heart(canvas, 203, 108 + math.sin(clock * 1.4) * 3, 10, Palette.pink);
    }
    if (frame.dim > 0) {
      canvas.drawColor(
        const Color(0xFF554666).withValues(alpha: frame.dim.clamp(0, .5)),
        BlendMode.srcOver,
      );
    }
    if (showAnchors || showBounds) _debug(canvas, frame, scale);
    canvas.restore();
  }

  void _bed(Canvas c, bool night) {
    const wood = Color(0xFFBD978A);
    const woodInk = Color(0xFF9C7D79);
    for (final x in [68.0, 319.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 292, 13, 19),
          const Radius.circular(4),
        ),
        fill(wood),
      );
    }
    final headboard = RRect.fromRectAndRadius(
      const Rect.fromLTWH(58, 162, 284, 124),
      const Radius.circular(24),
    );
    c.drawRRect(
      headboard,
      fill(night ? const Color(0xFFC7B3CE) : const Color(0xFFE5C6C5)),
    );
    c.drawRRect(headboard, stroke(woodInk, 2));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 172, 264, 101),
        const Radius.circular(18),
      ),
      stroke(const Color(0xFFF3E2E1), 1.5),
    );
    // The side wall and piping give the mattress real thickness above the rug.
    final mattress = RRect.fromRectAndRadius(
      const Rect.fromLTWH(51, 242, 298, 59),
      const Radius.circular(18),
    );
    c.drawRRect(mattress, fill(const Color(0xFFE8DCE6)));
    c.drawRRect(mattress, stroke(const Color(0xFFB69CAD), 1.8));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(53, 239, 294, 42),
        const Radius.circular(18),
      ),
      fill(const Color(0xFFFFF5ED)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(51, 289, 298, 14),
        const Radius.circular(6),
      ),
      fill(wood),
    );
    line(c, const Offset(63, 294), const Offset(337, 294), woodInk, 1);
  }

  void _pillows(Canvas c) {
    final sitting = action == AffectionType.cuddleTime;
    final centers = action == AffectionType.goodnightKiss
        ? [const Offset(266, 233)]
        : sitting
        ? [const Offset(113, 234), const Offset(287, 234)]
        : [const Offset(133, 233), const Offset(267, 233)];
    for (final center in centers) {
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate((center.dx < 200 ? -1 : 1) * (sitting ? .12 : .045));
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: sitting ? 76 : 136,
        height: sitting ? 64 : 45,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(const Offset(0, 4)),
          const Radius.circular(16),
        ),
        fill(const Color(0x22000000)),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        fill(const Color(0xFFFFF8F3)),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        stroke(const Color(0xFFD5BBCA), 1.4),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(12)),
        stroke(const Color(0xFFEAD8E0), 1),
      );
      c.restore();
    }
  }

  void _blanket(Canvas c, BearFrame frame) {
    final sleeping = action != AffectionType.cuddleTime;
    final left = action == AffectionType.goodnightKiss ? 193.0 : 53.0;
    const right = 347.0;
    final middle = (left + right) / 2;
    final breath = reduced ? 0.0 : (frame.left.breath + frame.right.breath) / 2;
    final y =
        (sleeping ? 270 : 284) -
        frame.blanket * (sleeping ? 32 : 38) +
        (reduced
            ? 0
            : (playback?.secondary.blanket.position ?? 0) *
                  (playback?.intensity ?? 1));
    final quilt = Path()
      ..moveTo(left + 6, y)
      ..quadraticBezierTo(middle, y - 9 - breath, right - 6, y + 1)
      ..quadraticBezierTo(right + 1, y + 16, right, 292)
      ..quadraticBezierTo(middle, 307, left, 293)
      ..quadraticBezierTo(left - 1, y + 16, left + 6, y)
      ..close();
    shape(c, quilt, Palette.sage, 1.8);
    c.save();
    c.clipPath(quilt);
    // A folded top edge sits over the bodies; the quilt hangs over the bed edge.
    final fold = Path()
      ..moveTo(left, y - 3)
      ..quadraticBezierTo(middle, y - 11 - breath, right, y - 2)
      ..lineTo(right, y + 12)
      ..quadraticBezierTo(middle, y + 3 - breath, left, y + 12)
      ..close();
    c.drawPath(fold, fill(const Color(0xFFD4E3C9)));
    c.drawPath(
      Path()
        ..moveTo(left, y + 12)
        ..quadraticBezierTo(middle, y + 3 - breath, right, y + 12),
      stroke(const Color(0xFF93B39A), 1.2),
    );
    for (var x = left + 24; x < right - 8; x += 34) {
      c.drawPath(
        Path()
          ..moveTo(x, y + 20)
          ..quadraticBezierTo(x - 4, 278, x + 2, 298),
        stroke(const Color(0xFF9DBB9E), .9),
      );
    }
    c.restore();
  }

  // Only the standalone workbench exposes these painter flags.
  void _debug(Canvas c, BearFrame frame, double scale) {
    for (final (p, name, color) in [
      (frame.left, sender.name, Colors.blue),
      (frame.right, sender.other.name, Colors.deepOrange),
    ]) {
      if (showBounds) {
        final points = [
          for (final x in [-66.0, 72.0])
            for (final y in [-64.0, 60.0]) p.headPoint(Offset(x, y)),
          p.bodyPoint(const Offset(-78, -15)),
          p.bodyPoint(const Offset(44, 0)),
        ];
        var bounds = Rect.fromPoints(points.first, points.first);
        for (final point in points.skip(1)) {
          bounds = bounds.expandToInclude(Rect.fromPoints(point, point));
        }
        c.drawRect(bounds, stroke(color.withValues(alpha: .6), 1));
      }
      if (showAnchors) {
        line(
          c,
          p.root - const Offset(5, 0),
          p.root + const Offset(5, 0),
          color,
        );
        line(
          c,
          p.root - const Offset(0, 5),
          p.root + const Offset(0, 5),
          color,
        );
        for (final anchor in BearAnchor.values) {
          final at = p.anchor(anchor);
          c.drawCircle(at, 2.2, fill(color));
        }
        for (final near in [true, false]) {
          final shoulder = p.anchor(
            near ? BearAnchor.shoulder : BearAnchor.rightShoulder,
          );
          final paw = BearVectorRig.paw(p, near: near);
          line(c, shoulder, paw, color.withValues(alpha: .5), 1);
          c.drawCircle(paw, 4, stroke(color, 1));
        }
      }
      final label = TextPainter(
        text: TextSpan(
          text:
              '$name · facing ${p.facing.toInt()} · scale ${scale.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 9, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(c, Offset(8, identical(p, frame.left) ? 307 : 319));
      label.dispose();
    }
    if (showAnchors) {
      for (final contact in frame.contacts) {
        line(c, contact.from, contact.to, Colors.purple, 1);
        c.drawCircle(contact.to, 4, stroke(Colors.purple, 1));
      }
    }
    final label = TextPainter(
      text: TextSpan(
        text:
            '${action?.name ?? 'idle'} · ${playback?.stage.name ?? BearChoreography.stage(t).name} · ${((playback?.progress ?? t) * 100).toStringAsFixed(1)}%',
        style: const TextStyle(fontSize: 10, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(c, const Offset(8, 6));
    label.dispose();
  }

  void _giftAnimated(Canvas c, Offset p, double open) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 46, height: 36),
        const Radius.circular(4),
      ),
      fill(Palette.lavender),
    );
    line(c, p.translate(0, -18), p.translate(0, 17), Palette.paper, 5);
    c.save();
    c.translate(p.dx - open * 6, p.dy - 19 - open * 25);
    c.rotate(-open * .14);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-25.5, -5, 51, 10),
        const Radius.circular(3),
      ),
      fill(const Color(0xFFC8B1D1)),
    );
    c.restore();
    if (open > 0) {
      _heart(c, p.dx, p.dy - 12 - open * 16, 10 * open, Palette.pink);
    }
  }

  void _room(Canvas c, bool night, bool dim) {
    final garden = theme == SceneTheme.flowerGarden;
    final sky = night ? const Color(0xFF877A9D) : const Color(0xFFD5CFDE);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(144, 23, 112, 107),
        const Radius.circular(53),
      ),
      fill(const Color(0xFFE7D7CB)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(151, 30, 98, 94),
        const Radius.circular(47),
      ),
      fill(sky),
    );
    if (night) {
      c.drawCircle(const Offset(219, 55), 11, fill(const Color(0xFFFFEAC9)));
      c.drawCircle(const Offset(224, 51), 10, fill(sky));
      for (final p in [
        const Offset(173, 58),
        const Offset(194, 43),
        const Offset(229, 90),
        const Offset(176, 91),
      ]) {
        _spark(c, p, 2.5, const Color(0xFFFCE9D3));
      }
    } else {
      oval(c, const Rect.fromLTWH(167, 65, 34, 12), const Color(0xFFECE7EF));
      oval(c, const Rect.fromLTWH(209, 47, 27, 10), const Color(0xFFECE7EF));
      c.drawCircle(const Offset(225, 83), 9, fill(const Color(0xFFF1DBC2)));
    }
    line(
      c,
      const Offset(200, 29),
      const Offset(200, 124),
      const Color(0xFFE7D7CB),
      5,
    );
    line(
      c,
      const Offset(151, 83),
      const Offset(248, 83),
      const Color(0xFFE7D7CB),
      5,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(139, 122, 122, 7),
        const Radius.circular(3),
      ),
      fill(const Color(0xFFCFB7A7)),
    );
    line(
      c,
      const Offset(0, 252),
      const Offset(66, 252),
      const Color(0xFFE2D0C2),
      1,
    );
    line(
      c,
      const Offset(333, 252),
      const Offset(400, 252),
      const Color(0xFFE2D0C2),
      1,
    );
    // A little plant and two books keep the room quiet and personal.
    line(
      c,
      const Offset(45, 204),
      const Offset(45, 154),
      const Color(0xFF8B9F7E),
      2,
    );
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(44, 164 + i * 13.0);
      c.rotate(i.isEven ? -.7 : .7);
      oval(c, const Rect.fromLTWH(-17, -6, 19, 10), const Color(0xFFB0C0A0));
      c.restore();
    }
    final pot = Path()
      ..moveTo(30, 200)
      ..lineTo(60, 200)
      ..lineTo(55, 224)
      ..quadraticBezierTo(45, 229, 35, 224)
      ..close();
    c.drawPath(pot, fill(const Color(0xFFD8AA91)));
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(338, 191, 34, 6),
        const Radius.circular(2),
      ),
      fill(const Color(0xFFC6AFC7)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(343, 184, 27, 6),
        const Radius.circular(2),
      ),
      fill(const Color(0xFFE7C0B1)),
    );
    line(
      c,
      const Offset(334, 200),
      const Offset(377, 200),
      const Color(0xFFC8AF9E),
      4,
    );
    if (garden) {
      _flower(c, 46, 260, .8);
      _flower(c, 355, 253, .7);
    }
    if (theme == SceneTheme.rainyWindow || action?.scene == 'rain') {
      for (var i = 0; i < 8; i++) {
        final y = 40 + ((i * 17 + clock * 18) % 75);
        line(
          c,
          Offset(164 + i * 10.0, y),
          Offset(162 + i * 10.0, y + 6),
          const Color(0xFFB9ACC8),
          1.5,
        );
      }
    }
    if (action?.scene == 'sleep') {
      line(
        c,
        const Offset(348, 213),
        const Offset(348, 246),
        const Color(0xFF9F857D),
        3,
      );
      final lamp = Path()
        ..moveTo(336, 209)
        ..lineTo(341, 190)
        ..lineTo(355, 190)
        ..lineTo(361, 209)
        ..close();
      c.drawPath(
        lamp,
        fill(dim ? const Color(0xFF9986A3) : const Color(0xFFF5D8AE)),
      );
    }
  }

  void _heart(Canvas c, double x, double y, double s, Color color) {
    final p = Path()
      ..moveTo(x, y + s * .6)
      ..cubicTo(x - s * 1.6, y - s * .3, x - s * .6, y - s * 1.2, x, y - s * .5)
      ..cubicTo(
        x + s * .6,
        y - s * 1.2,
        x + s * 1.6,
        y - s * .3,
        x,
        y + s * .6,
      );
    c.drawPath(p, fill(color));
  }

  void _flower(Canvas c, double x, double y, double s) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    line(
      c,
      const Offset(0, 0),
      const Offset(0, 24),
      const Color(0xFF7C9A77),
      2.5,
    );
    oval(c, const Rect.fromLTWH(0, 9, 13, 7), Palette.sage);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      c.drawCircle(
        Offset(math.cos(a) * 7, math.sin(a) * 7),
        5.5,
        fill(Palette.pink),
      );
    }
    c.drawCircle(Offset.zero, 4, fill(const Color(0xFFF6D798)));
    c.restore();
  }

  void _umbrella(Canvas c) {
    line(
      c,
      const Offset(200, 95),
      const Offset(200, 222),
      const Color(0xFFA98B77),
      3,
    );
    final p = Path()
      ..moveTo(108, 104)
      ..quadraticBezierTo(200, -7, 292, 104)
      ..quadraticBezierTo(270, 91, 246, 106)
      ..quadraticBezierTo(222, 91, 200, 106)
      ..quadraticBezierTo(177, 91, 153, 106)
      ..quadraticBezierTo(130, 91, 108, 104);
    shape(c, p, Palette.blush, 2);
  }

  void _spark(Canvas c, Offset p, double r, Color color) {
    line(c, p.translate(-r, 0), p.translate(r, 0), color, 1.5);
    line(c, p.translate(0, -r), p.translate(0, r), color, 1.5);
  }

  @override
  bool shouldRepaint(covariant BearScenePainter old) =>
      playback != old.playback ||
      t != old.t ||
      action != old.action ||
      sender != old.sender ||
      theme != old.theme ||
      holding != old.holding ||
      taps != old.taps ||
      walk != old.walk ||
      reduced != old.reduced ||
      accessory != old.accessory ||
      variant != old.variant ||
      showAnchors != old.showAnchors ||
      showBounds != old.showBounds ||
      stopped != old.stopped;
}
