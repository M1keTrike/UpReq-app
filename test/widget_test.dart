import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/core/database/database_provider.dart';

import 'package:up_req/main.dart';

import 'support/test_database.dart';

void main() {
  testWidgets('arranca en la lista de proyectos', (WidgetTester tester) async {
    final db = openTestDatabase();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const UpReqApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proyectos'), findsWidgets);
  });
}
