import 'package:drift/drift.dart';

/// Todo `DateTimeColumn` de este esquema pasa por este converter: sin él,
/// drift devuelve un `DateTime` en hora local al leer, y como `DateTime.==`
/// distingue UTC de local aunque representen el mismo instante, cualquier
/// comparación entre un valor recién escrito (`DateTime.utc(...)`) y el mismo
/// valor releído fallaría. data-model.md exige "epoch UTC" (el analista
/// cruza husos horarios en campo); este converter lo garantiza en tiempo de
/// ejecución, no solo en el tipo de columna SQL.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toUtc();

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
