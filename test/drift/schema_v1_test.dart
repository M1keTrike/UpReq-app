import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';
import 'package:up_req/core/database/app_database.dart';

import 'app_database/generated/schema.dart';

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('la base creada desde cero coincide con el snapshot de la versión 1', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });
}
