import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bear_with_me/app/theme/app_theme.dart';
import 'package:bear_with_me/core/widgets/app_shell.dart';
import 'package:bear_with_me/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('export desktop and phone UI for visual review', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final key = GlobalKey();
    for (final spec in [('desktop', 1200.0, 950.0), ('phone', 390.0, 1050.0)]) {
      tester.view.physicalSize = Size(spec.$2, spec.$3);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ProviderScope(
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              home: const AppShell(
                path: '/studio',
                studio: true,
                child: HomeScreen(studio: true),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('artifacts').create(recursive: true);
        await File('artifacts/home-${spec.$1}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
