import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_with_me/features/pairing/data/pairing_repository.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/settings/data/settings_repository.dart';

void main() {
  test(
    'invitation secrets are 256-bit URL-safe tokens with unpredictable hashes',
    () {
      final tokens = List.generate(200, (_) => generateInvitationToken());
      expect(tokens.toSet().length, 200);
      for (final token in tokens) {
        expect(RegExp(r'^[\w-]{43}$').hasMatch(token), isTrue);
        expect(invitationIdFor(token), hasLength(64));
      }
      expect(invitationIdFor('A' * 43), invitationIdFor('A' * 43));
      expect(() => invitationIdFor('123456'), throwsFormatException);
    },
  );
  test(
    'every catalog interaction is explicitly authorized in deployed rules',
    () {
      final rules = File('firebase/firestore.rules').readAsStringSync();
      expect(AffectionType.values.length, 24);
      for (final type in AffectionType.values) {
        expect(rules, contains("'${type.name}'"));
        expect(type.gesture, isNotEmpty);
        expect(AffectionType.parse(type.name), type);
      }
      expect(() => AffectionType.parse('unknown'), throwsFormatException);
      expect(BearCharacter.brown.other, BearCharacter.white);
    },
  );
  test(
    'non-sensitive settings serialize and preserve independent switches',
    () {
      const settings = AppSettings(
        sound: true,
        haptics: false,
        reducedMotion: true,
      );
      final result = AppSettings.fromJson(settings.toJson());
      expect(result.sound, isTrue);
      expect(result.haptics, isFalse);
      expect(result.reducedMotion, isTrue);
      expect(result.copyWith(notifications: false).sound, isTrue);
    },
  );
}
