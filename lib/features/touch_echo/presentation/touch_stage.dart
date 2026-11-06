import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/app_theme.dart';
import '../../affection/domain/affection_type.dart';
import '../../animation/presentation/bear_choreography.dart';
import '../../animation/presentation/bear_physics.dart';
import '../../animation/presentation/bear_vector_rig.dart';
import '../domain/touch_intent.dart';
import 'touch_geometry.dart';
import 'touch_input_controller.dart';
import 'touch_playback.dart';

class TouchStage extends StatefulWidget {
  const TouchStage({
    super.key,
    required this.bear,
    this.intent,
    this.onResult,
    this.onComplete,
    this.onContact,
    this.reducedMotion = false,
    this.guides = false,
    this.heartMode = false,
    this.debugAnchors = false,
    this.sensitivity = 1,
    this.motionScale = 1,
    this.initialProgress = 0,
    this.frozen = false,
  });
  final BearCharacter bear;
  final TouchIntent? intent;
  final ValueChanged<TouchResult>? onResult;
  final VoidCallback? onComplete;
  final VoidCallback? onContact;
  final bool reducedMotion, guides, heartMode, debugAnchors;
  final double sensitivity, motionScale, initialProgress;
  final bool frozen;
  @override
  State<TouchStage> createState() => _TouchStageState();
}

class _TouchStageState extends State<TouchStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  late final TouchInputController _input;
  final _secondary = BearSecondaryMotion();
  final _contact = BearSpring(frequency: 18, damping: 1, limit: 1);
  final _tilt = BearSpring(frequency: 12, damping: .92, limit: .12);
  final _ear = BearSpring(frequency: 16, damping: .8, limit: .12);
  Duration? _last;
  double _time = 0, _localAge = 0, _accumulator = 0;
  bool _completed = false, _foreground = true, _contactStarted = false;
  TouchKind _localKind = TouchKind.headPet;
  Offset? _finger;
  final Set<int> _pointers = {};
  bool _rightEar = true;
  bool get _reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
  double get _progress => widget.intent == null
      ? 0
      : (_time / (widget.intent!.playbackMs / 1000)).clamp(0, 1);
  BearPose get _solo {
    final p = TouchPlayback.solo();
    TouchPlayback.reaction(
      p,
      _localKind,
      _contact.position.clamp(0, 1),
      _localAge * .4,
      widget.motionScale,
      reduced: _reduced,
      direction: _finger == null ? 1 : ((_finger!.dx - 200) / 50).clamp(-1, 1),
    );
    p.head += _tilt.position;
    p.ear = _ear.position;
    if (_localKind == TouchKind.earRub && !_rightEar) {
      p.leftEarBend = p.rightEarBend;
      p.rightEarBend = 0;
    }
    return p;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _time = (widget.intent?.playbackMs ?? 0) / 1000 * widget.initialProgress;
    _input = TouchInputController(
      onResult: (r) {
        if (r.intent != null) _localKind = r.intent!.kind;
        widget.onResult?.call(r);
      },
    );
    _tuneSprings();
    _ticker = createTicker(_tick);
  }

  void _tuneSprings() {
    _secondary.right.head.damping = widget.intent?.style == TouchStyle.playful
        ? .85
        : 1;
    _secondary.right.ear.damping = switch (widget.intent?.style) {
      TouchStyle.playful => .73,
      TouchStyle.normal => .85,
      _ => .97,
    };
  }

  void _wake() {
    if (!widget.frozen &&
        _foreground &&
        !_ticker.isActive &&
        TickerMode.valuesOf(context).enabled) {
      _last = null;
      _ticker.start();
    }
  }

  void _tick(Duration now) {
    final double dt = _last == null
        ? 0.0
        : ((now - _last!).inMicroseconds / 1e6).clamp(0.0, .133);
    _last = now;
    _localAge += dt;
    if (widget.intent != null) {
      _time += dt;
      if (!_contactStarted && _progress >= .34 && _progress < .8) {
        _contactStarted = true;
        if (!_reduced) {
          _secondary.right.react(switch (widget.intent!.kind) {
            TouchKind.noseBoop => BearReaction.boop,
            TouchKind.tinyTickle => BearReaction.belly,
            TouchKind.backComfort || TouchKind.hugHold => BearReaction.relax,
            _ => BearReaction.pet,
          });
        }
        widget.onContact?.call();
      }
      final head = TouchPlayback.sample(
        widget.intent!,
        _progress,
        reduced: _reduced,
      ).right.head;
      _secondary.advance(dt, rightHead: head);
    } else {
      _accumulator = math.min(_accumulator + dt, 8 / 60);
      while (_accumulator >= 1 / 60) {
        _contact.target = _input.tracking ? 1 : 0;
        _contact.step(1 / 60);
        _tilt.target = _input.tracking && !_reduced
            ? ((_finger?.dx ?? 200) - 200) / 900
            : 0;
        _tilt.target = _tilt.target.clamp(-.08, .08);
        _tilt.step(1 / 60);
        _ear.target = -_tilt.position * .65;
        _ear.step(1 / 60);
        _accumulator -= 1 / 60;
      }
    }
    setState(() {});
    if (widget.intent != null && _progress >= 1 && !_completed) {
      _completed = true;
      _ticker.stop();
      widget.onComplete?.call();
    } else if (widget.intent == null &&
        !_input.tracking &&
        _contact.position.abs() < .0001 &&
        _tilt.position.abs() < .0001 &&
        _ear.position.abs() < .0001) {
      _ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.intent != null) _wake();
  }

  @override
  void didUpdateWidget(TouchStage old) {
    super.didUpdateWidget(old);
    if (old.intent != widget.intent) {
      _input.cancel();
      _secondary.reset();
      _contact.reset();
      _tilt.reset();
      _ear.reset();
      _time = 0;
      _completed = false;
      _contactStarted = false;
      _tuneSprings();
      _last = null;
      if (widget.intent != null) _wake();
    }
    if (old.reducedMotion != widget.reducedMotion ||
        old.heartMode != widget.heartMode) {
      _input.cancel();
      _finger = null;
    }
  }

  void _cancel() {
    _input.cancel();
    _finger = null;
    _contact.target = 0;
    _tilt.target = 0;
    _wake();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _pointers.clear();
      _input.cancel();
      _finger = null;
      _ticker.stop();
      _last = null;
      _accumulator = 0;
      _contact.reset();
      _tilt.reset();
      _ear.reset();
      _secondary.reset();
    } else if (widget.intent != null && !_completed) {
      _wake();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      Offset? at(Offset p) => TouchGeometry.scenePoint(
        p,
        size,
        zoom: widget.intent == null ? TouchGeometry.localZoom : 1,
      );
      final scene = Semantics(
        image: true,
        label: widget.intent == null
            ? '${widget.bear.name} bear. Stroke the head or choose Touch actions below.'
            : '${widget.bear.name} bear gives ${widget.bear.other.name} bear ${widget.intent!.kind.title}',
        child: RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: TouchStagePainter(
              bear: widget.bear,
              solo: widget.intent == null ? _solo : null,
              intent: widget.intent,
              progress: _progress,
              reduced: _reduced,
              guides: widget.guides,
              debugAnchors: kDebugMode && widget.debugAnchors,
              secondary: _secondary,
              finger: _finger,
              trace: _input.heartMode
                  ? _input.samples.map((e) => e.point * 100).toList()
                  : const [],
              motionScale: widget.motionScale,
            ),
          ),
        ),
      );
      if (widget.intent != null || widget.onResult == null) return scene;
      return GestureDetector(
        onPanUpdate: (_) {},
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _pointers.add(e.pointer);
            if (_pointers.length > 1) {
              _cancel();
              return;
            }
            final p = at(e.localPosition);
            if (p == null) return;
            _input.heartMode = widget.heartMode;
            _input.sensitivity = widget.sensitivity;
            final zone = TouchGeometry.hit(_solo, p);
            _rightEar = TouchGeometry.headLocal(_solo, p).dx >= 0;
            _input.begin(e.pointer, zone, p / 100, e.timeStamp);
            if (_input.tracking) {
              _finger = p;
              _localAge = 0;
              _localKind = switch (zone) {
                TouchZone.nose => TouchKind.noseBoop,
                TouchZone.cheek => TouchKind.cheekCaress,
                TouchZone.paw => TouchKind.pawHold,
                TouchZone.ear => TouchKind.earRub,
                TouchZone.chest => TouchKind.hugHold,
                TouchZone.belly => TouchKind.bellyRub,
                TouchZone.back => TouchKind.backComfort,
                _ => TouchKind.headPet,
              };
              _wake();
            }
          },
          onPointerMove: (e) {
            final p = at(e.localPosition);
            if (p == null) {
              _cancel();
              return;
            }
            final inside = widget.heartMode || TouchGeometry.contains(_solo, p);
            if (_input.move(e.pointer, p / 100, e.timeStamp, inside: inside)) {
              _finger = p;
            }
          },
          onPointerUp: (e) {
            _pointers.remove(e.pointer);
            final p = at(e.localPosition);
            if (p == null) {
              _cancel();
              return;
            }
            _input.end(
              e.pointer,
              p / 100,
              e.timeStamp,
              inside: widget.heartMode || TouchGeometry.contains(_solo, p),
            );
            _finger = null;
            _wake();
          },
          onPointerCancel: (e) {
            _pointers.remove(e.pointer);
            _cancel();
          },
          child: scene,
        ),
      );
    },
  );
}

class TouchStagePainter extends CustomPainter {
  TouchStagePainter({
    required this.bear,
    this.solo,
    this.intent,
    this.progress = 0,
    this.reduced = false,
    this.guides = false,
    this.debugAnchors = false,
    this.secondary,
    this.finger,
    this.trace = const [],
    this.motionScale = 1,
  });
  final BearCharacter bear;
  final BearPose? solo;
  final TouchIntent? intent;
  final double progress, motionScale;
  final bool reduced, guides, debugAnchors;
  final BearSecondaryMotion? secondary;
  final Offset? finger;
  final List<Offset> trace;
  @override
  void paint(Canvas c, Size size) {
    if (size.isEmpty) return;
    final scale = math.min(size.width / 400, size.height / 340);
    c.save();
    c.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 340 * scale) / 2,
    );
    c.scale(scale);
    c.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 400, 340),
        const Radius.circular(28),
      ),
    );
    c.drawRect(
      const Rect.fromLTWH(0, 0, 400, 340),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8EF), Color(0xFFF0DFD4)],
        ).createShader(const Rect.fromLTWH(0, 0, 400, 340)),
    );
    c.drawOval(
      const Rect.fromLTWH(48, 270, 304, 35),
      Paint()..color = const Color(0x24BC8A75),
    );
    if (intent == null) {
      c.translate(200, 210);
      c.scale(TouchGeometry.localZoom);
      c.translate(-200, -210);
    }
    final f = intent == null
        ? null
        : TouchPlayback.sample(
            intent!,
            progress,
            reduced: reduced,
            secondary: secondary,
            motionScale: motionScale,
          );
    final actors = f == null
        ? [(solo ?? TouchPlayback.solo(), bear)]
        : [(f.left, bear), (f.right, bear.other)];
    for (final (p, _) in actors) {
      c.drawOval(
        Rect.fromCenter(center: Offset(p.root.dx, 280), width: 72, height: 8),
        Paint()..color = const Color(0x22352320),
      );
    }
    for (final (p, b) in actors) {
      BearVectorRig.arm(c, p, b, near: false);
    }
    for (final (p, b) in actors) {
      BearVectorRig.draw(c, p, b, 'none', arms: false);
    }
    // Contact paws are drawn above the target silhouette; the connecting upper
    // arm stays behind faces, leaving the receiver's eyes readable.
    for (final (p, b) in actors) {
      final contactArm =
          f != null &&
          identical(p, f.left) &&
          intent!.kind != TouchKind.hugHold &&
          intent!.kind != TouchKind.heartTrace &&
          TouchPlayback.contactWeight(progress) > .02;
      BearVectorRig.arm(
        c,
        p,
        b,
        foreground: !contactArm,
        occluders: actors.where((e) => e.$1 != p).map((e) => e.$1).toList(),
      );
    }
    if (f != null &&
        ![TouchKind.heartTrace, TouchKind.hugHold].contains(intent!.kind)) {
      for (final contact in f.contacts.where((e) => e.weight > .05).take(1)) {
        // The arm renderer supplies the outlined paw; no disconnected overlay
        // cap can hide an unreachable or occluded endpoint.
        if (debugAnchors) {
          c.drawCircle(contact.to, 3, Paint()..color = Colors.green);
        }
      }
    }
    if (f != null && intent!.kind == TouchKind.heartTrace && f.effect > 0) {
      final path = Path();
      final points = _heartPoints();
      final count = (points.length * rampHeart(progress)).round().clamp(
        2,
        points.length,
      );
      final landing = TouchPlayback.ramp(progress, .5, .73);
      for (var i = 0; i < count; i++) {
        final p = Offset.lerp(
          points[i] + const Offset(200, 136),
          f.prop + (points[i] * .23),
          landing,
        )!;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      c.drawPath(
        path,
        Paint()
          ..color = Palette.rose.withValues(alpha: f.effect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (trace.length > 1) {
      final p = Path()..moveTo(trace.first.dx, trace.first.dy);
      for (final v in trace.skip(1)) {
        p.lineTo(v.dx, v.dy);
      }
      c.drawPath(
        p,
        Paint()
          ..color = Palette.rose
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (finger != null) {
      c.drawCircle(
        finger!,
        7,
        Paint()..color = Palette.pink.withValues(alpha: .35),
      );
    }
    if (f == null && guides) {
      final p = solo ?? TouchPlayback.solo();
      for (final (anchor, label) in [
        (BearAnchor.headTop, 'Head'),
        (BearAnchor.leftEar, 'Ear'),
        (BearAnchor.nose, 'Nose'),
        (BearAnchor.leftCheek, 'Cheek'),
        (BearAnchor.leftPaw, 'Paw'),
        (BearAnchor.belly, 'Belly'),
        (BearAnchor.back, 'Shoulder'),
      ]) {
        final at = p.anchor(anchor);
        c.drawCircle(
          at,
          7,
          Paint()..color = Palette.rose.withValues(alpha: .12),
        );
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 10,
              color: Palette.rose,
              fontFamily: 'Nunito',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(c, at + const Offset(9, -7));
        text.dispose();
      }
    }
    if (debugAnchors) {
      for (final (p, _) in actors) {
        for (final anchor in BearAnchor.values) {
          c.drawCircle(p.anchor(anchor), 2, Paint()..color = Colors.blue);
        }
      }
    }
    c.restore();
  }

  double rampHeart(double t) => TouchPlayback.ramp(t, .17, .50);
  List<Offset> _heartPoints() => List.generate(64, (i) {
    final t = i / 63 * math.pi * 2;
    return Offset(
      16 * math.pow(math.sin(t), 3).toDouble() * 1.6,
      -(13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t)) *
          1.6,
    );
  });
  @override
  bool shouldRepaint(covariant TouchStagePainter old) => true;
}
