import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meetspace_web/main.dart';

void main() {
  testWidgets('App loads and shows landing or loading', (WidgetTester tester) async {
    await tester.pumpWidget(const MeetSpaceApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
