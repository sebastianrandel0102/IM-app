import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import '../../affection/domain/affection_type.dart';

/// Opt-in adapter for docs/animations/AUTHORING.md. No .riv files are supplied.
class RiveBearScene extends StatefulWidget {
  const RiveBearScene({
    super.key,
    required this.fallback,
    required this.action,
    required this.sender,
    required this.holding,
    required this.taps,
    required this.reducedMotion,
    required this.variant,
  });
  final Widget fallback;
  final AffectionType? action;
  final BearCharacter sender;
  final bool holding, reducedMotion;
  final int taps;
  final String variant;
  @override
  State<RiveBearScene> createState() => _RiveBearSceneState();
}

class _RiveBearSceneState extends State<RiveBearScene> {
  late final _loader = rive.FileLoader.fromAsset(
    'assets/rive/bear_world.riv',
    riveFactory: rive.Factory.rive,
  );
  rive.ViewModelInstance? _model;
  void _apply() {
    final model = _model;
    if (model == null) return;
    model.number('Action')?.value = (widget.action?.index ?? -1) + 1.0;
    model.number('SenderRole')?.value = widget.sender.index.toDouble();
    model.number('ReceiverRole')?.value = widget.sender.other.index.toDouble();
    model.number('Variant')?.value = AffectionVariant.values
        .indexWhere((v) => v.name == widget.variant)
        .clamp(0, 2)
        .toDouble();
    model.boolean('HoldActive')?.value = widget.holding;
    model.boolean('ReducedMotion')?.value = widget.reducedMotion;
  }

  @override
  void didUpdateWidget(RiveBearScene old) {
    super.didUpdateWidget(old);
    _apply();
    if (old.taps != widget.taps) _model?.trigger('TapTrigger')?.trigger();
  }

  @override
  void dispose() {
    _model = null;
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => rive.RiveWidgetBuilder(
    fileLoader: _loader,
    dataBind: rive.DataBind.auto(),
    stateMachineSelector: rive.StateMachineSelector.byName('BearWorld'),
    onLoaded: (loaded) {
      _model = loaded.viewModelInstance;
      _apply();
    },
    builder: (context, state) => switch (state) {
      rive.RiveLoaded() => rive.RiveWidget(
        controller: state.controller,
        fit: rive.Fit.contain,
      ),
      _ => widget.fallback,
    },
  );
}
