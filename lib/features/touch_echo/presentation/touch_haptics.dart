import 'package:flutter/services.dart';

import '../../settings/data/settings_repository.dart';
import '../domain/touch_intent.dart';

/// Platform presets rather than a promise of hardware pressure or amplitude.
void touchHaptic(AppSettings settings, TouchStyle style) {
  if (!settings.haptics || settings.touchHapticStrength == 0) return;
  final strength =
      settings.touchHapticStrength * (style == TouchStyle.gentle ? .6 : 1);
  if (strength < .5) {
    HapticFeedback.selectionClick();
  } else {
    HapticFeedback.lightImpact();
  }
}
