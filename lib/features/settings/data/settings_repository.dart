import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.sound = false,
    this.haptics = true,
    this.reducedMotion = false,
    this.notifications = true,
    this.animationIntensity = 1,
    this.touchSensitivity = 1,
    this.touchHapticStrength = .4,
  });
  final bool sound, haptics, reducedMotion, notifications;
  final double animationIntensity;
  final double touchSensitivity;
  final double touchHapticStrength;
  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    bool? reducedMotion,
    bool? notifications,
    double? animationIntensity,
    double? touchSensitivity,
    double? touchHapticStrength,
  }) => AppSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    notifications: notifications ?? this.notifications,
    touchHapticStrength: (touchHapticStrength ?? this.touchHapticStrength)
        .clamp(0, 1),
    touchSensitivity: (touchSensitivity ?? this.touchSensitivity).clamp(
      .7,
      1.4,
    ),
    animationIntensity: (animationIntensity ?? this.animationIntensity).clamp(
      0,
      1,
    ),
  );
  Map<String, dynamic> toJson() => {
    'sound': sound,
    'haptics': haptics,
    'reducedMotion': reducedMotion,
    'notifications': notifications,
    'animationIntensity': animationIntensity,
    'touchSensitivity': touchSensitivity,
    'touchHapticStrength': touchHapticStrength,
  };
  factory AppSettings.fromJson(Map<String, dynamic> d) => AppSettings(
    sound: d['sound'] == true,
    haptics: d['haptics'] != false,
    reducedMotion: d['reducedMotion'] == true,
    notifications: d['notifications'] != false,
    touchHapticStrength:
        d['touchHapticStrength'] is num &&
            (d['touchHapticStrength'] as num).isFinite
        ? (d['touchHapticStrength'] as num).toDouble().clamp(0, 1)
        : .4,
    touchSensitivity:
        d['touchSensitivity'] is num && (d['touchSensitivity'] as num).isFinite
        ? (d['touchSensitivity'] as num).toDouble().clamp(.7, 1.4)
        : 1,
    animationIntensity:
        d['animationIntensity'] is num &&
            (d['animationIntensity'] as num).isFinite
        ? (d['animationIntensity'] as num).toDouble().clamp(0, 1)
        : 1,
  );
}

class SettingsRepository extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString('settings');
    if (text != null && ref.mounted) {
      try {
        state = AppSettings.fromJson(jsonDecode(text) as Map<String, dynamic>);
      } catch (_) {
        /* Non-sensitive settings can be reset. */
      }
    }
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await (await SharedPreferences.getInstance()).setString(
      'settings',
      jsonEncode(settings.toJson()),
    );
  }
}

final settingsProvider = NotifierProvider<SettingsRepository, AppSettings>(
  SettingsRepository.new,
);
