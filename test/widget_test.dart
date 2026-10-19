import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dropzy_mobile/widgets/common.dart';
import 'package:dropzy_mobile/core/theme.dart';

void main() {
  testWidgets('Dropzy logo renders wordmark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDropzyTheme(),
        home: const Scaffold(body: Center(child: DropzyLogo())),
      ),
    );

    expect(find.text('Dropzy'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
  });
}
