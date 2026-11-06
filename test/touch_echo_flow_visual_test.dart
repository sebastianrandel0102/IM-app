import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/core/services/providers.dart';
import 'package:bear_with_me/features/affection/domain/affection_type.dart';
import 'package:bear_with_me/features/affection/domain/models.dart';
import 'package:bear_with_me/features/affection/data/affection_repository.dart';
import 'package:bear_with_me/features/inbox/presentation/inbox_screens.dart';
import 'package:bear_with_me/features/animation/presentation/player_screen.dart';
import 'package:bear_with_me/features/touch_echo/domain/touch_intent.dart';
import 'package:bear_with_me/features/touch_echo/data/touch_echo_repository.dart';
import 'package:bear_with_me/features/touch_echo/presentation/touch_mode_screen.dart';

// Render-only fixtures; no mocked delivery is shipped. Firebase delivery and
// access-state transitions are independently exercised by the real emulators.
class ViewerFixture extends Fake implements User {
  @override
  String get uid => 'viewer';
}

class StatusFixture extends Fake implements AffectionRepository {
  int completed = 0;
  @override
  Future<void> complete(String id) async {
    completed++;
  }
}

void main() {
  testWidgets(
    'sealed inbox stays generic; revealed scene completes and Touch Back carries its thread',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      for (final (family, path) in [
        ('Nunito', 'assets/fonts/Nunito.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        final font = FontLoader(family)..addFont(rootBundle.load(path));
        await font.load();
      }
      tester.view.physicalSize = const Size(440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final i = TouchIntent(
        kind: TouchKind.headPet,
        style: TouchStyle.gentle,
        intensity: .3,
        durationMs: 1800,
        seed: 123,
      );
      final payload = ProtectedMomentPayload(
        momentId: 'render-fixture',
        type: AffectionType.headPat,
        variant: 'gentle',
        personalMessage: '',
        senderBear: BearCharacter.brown,
        receiverBear: BearCharacter.white,
        touch: i,
      );
      final status = StatusFixture();
      final pair = CouplePair(
        invitationId: 'visual-world',
        creatorUid: 'sender',
        receiverUid: 'viewer',
        creatorBear: BearCharacter.brown,
        status: 'active',
        approvedBy: const ['sender', 'viewer'],
      );
      final overrides = [
        touchEchoRepositoryProvider.overrideWithValue(null),
        receiveTouchesProvider.overrideWith((ref) => Stream.value(true)),
        authProvider.overrideWith((ref) => Stream.value(ViewerFixture())),
        pairProvider.overrideWith((ref) => Stream.value(pair)),
        partnerProvider.overrideWith(
          (ref) => Stream.value(
            const AppUser(
              uid: 'sender',
              displayName: 'Your partner',
              accessory: 'none',
            ),
          ),
        ),
        affectionRepositoryProvider.overrideWithValue(status),
        inboxProvider.overrideWith(
          (ref) => Stream.value([
            AffectionMoment(
              id: 'render-fixture',
              senderUid: 'sender',
              receiverUid: 'viewer',
              touchEcho: true,
              createdAt: DateTime(2026, 11, 1),
            ),
          ]),
        ),
      ];
      Future<void> capture(String name) async {
        await tester.pump();
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final img = await render.toImage(pixelRatio: 1);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('artifacts/touch_echo')
            ..createSync(recursive: true);
          await File('${dir.path}/$name.png')
              .writeAsBytes(data!.buffer.asUint8List());
          img.dispose();
        });
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: const Scaffold(body: InboxScreen()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('Gentle Head Pet'), findsNothing);
      expect(find.text('Open Touch Echo'), findsOneWidget);
      await capture('inbox-fixture');
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: const SurpriseScreen(id: 'render-fixture'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Gentle Head Pet'), findsNothing);
      await capture('sealed-envelope-fixture');
      await tester.pumpWidget(const SizedBox());
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => PlayerScreen(payload: payload),
          ),
          GoRoute(
            path: '/touch',
            builder: (_, s) => TouchModeScreen(
              studio: false,
              replyTo: s.uri.queryParameters['replyTo'],
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pump();
      for (var f = 0; f < 36; f++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Gentle Head Pet'), findsOneWidget);
      expect(
        find.text(AffectionType.headPat.message),
        findsNothing,
        reason: 'Touch Echo never inherits legacy quote cards or character dialogue',
      );
      await capture('reveal-fixture');
      for (var f = 0; f < 60; f++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(status.completed, 1);
      expect(find.text('Touch Back'), findsOneWidget);
      await tester.ensureVisible(find.text('Touch Back'));
      await tester.tap(find.text('Touch Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        router.routeInformationProvider.value.uri.queryParameters['replyTo'],
        'render-fixture',
      );
      expect(find.textContaining('Touch Back ·'), findsOneWidget);
      await capture('touch-back-fixture');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
