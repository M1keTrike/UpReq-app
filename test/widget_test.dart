import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:up_req/main.dart';

void main() {
  testWidgets('arranca en la lista de proyectos', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UpReqApp()));
    await tester.pumpAndSettle();

    expect(find.text('Lista de proyectos'), findsWidgets);
  });
}
