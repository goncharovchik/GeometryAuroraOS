import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geometry_dash_aurora/main.dart';

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
    expect(find.text('СКИН'), findsOneWidget);
    expect(find.text('НАСТРОЙКИ'), findsOneWidget);
  });
}
