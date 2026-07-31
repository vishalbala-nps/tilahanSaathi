import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilahan_saathi/app.dart';

void main() {
  testWidgets('Tilahan Saathi app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TilahanSaathiApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash screen's navigation timer complete so no timer is
    // left pending when the test tears down.
    await tester.pump(const Duration(seconds: 2));
  });
}
