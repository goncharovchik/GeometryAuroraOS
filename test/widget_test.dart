import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_dash_aurora/main.dart';
import 'package:geometry_dash_aurora/presentation/widgets/landscape_enforcer.dart';

void main() {
  testWidgets('Рендеринг главного меню Geometry Dash Aurora', (WidgetTester tester) async {
    await tester.pumpWidget(const GeometryDashApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Проверяем заголовок
    expect(find.text('GEOMETRY DASH'), findsOneWidget);
    expect(find.text('AURORA OS EDITION'), findsOneWidget);

    // Проверяем наличие кнопки PLAY
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Проверяем кнопки меню
    expect(find.text('УРОВНИ'), findsOneWidget);
    expect(find.text('МАСТЕРСКАЯ'), findsOneWidget);
    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
  });

  testWidgets('LandscapeEnforcer автоматически разворачивает вертикальный экран в горизонтальный', (WidgetTester tester) async {
    // Симулируем вертикальный экран телефона/эмулятора: 720 ширины на 1280 высоты
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: LandscapeEnforcer(
          child: Text('Game Screen Content'),
        ),
      ),
    );

    // При вертикальном экране должен быть создан RotatedBox с quarterTurns: 1
    final rotatedBoxFinder = find.byType(RotatedBox);
    expect(rotatedBoxFinder, findsOneWidget);
    final rotatedBox = tester.widget<RotatedBox>(rotatedBoxFinder);
    expect(rotatedBox.quarterTurns, equals(1));
  });
}
