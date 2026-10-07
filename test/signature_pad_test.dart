import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truck_app/src/features/pod_signature/presentation/signature_pad.dart';

void main() {
  testWidgets('signature pad exports drawn strokes as PNG base64', (
    tester,
  ) async {
    String? signature;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignaturePad(onSaved: (value) => signature = value),
        ),
      ),
    );

    final pad = find.byType(GestureDetector).first;
    final bounds = tester.getRect(pad);
    await tester.dragFrom(
      Offset(bounds.left + 20, bounds.top + 40),
      const Offset(120, 20),
    );
    await tester.pump();
    await tester.tap(find.text('Save signature'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(signature, isNotNull);
    final png = base64Decode(signature!);
    expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
