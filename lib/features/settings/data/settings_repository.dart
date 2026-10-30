import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.sound = false,
    this.haptics = true,
    this.reducedMotion = false,
    this.notifications = true,
  });
  final bool sound, haptics, reducedMotion, notifications;
  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    bool? reducedMotion,
    bool? notifications,
  }) => AppSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    notifications: notifications ?? this.notifications,
  );
  Map<String, dynamic> toJson() => {
    'sound': sound,
    'haptics': haptics,
    'reducedMotion': reducedMotion,
    'notifications': notifications,
  };
  factory AppSettings.fromJson(Map<String, dynamic> d) => AppSettings(
    sound: d['sound'] == true,
    haptics: d['haptics'] != false,
    reducedMotion: d['reducedMotion'] == true,
    notifications: d['notifications'] != false,
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
