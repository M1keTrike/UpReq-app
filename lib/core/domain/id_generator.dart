import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'id_generator.g.dart';

/// Generador de identificadores inyectable: acuña UUID v4 en producción y
/// admite sobreescritura con una secuencia fija en pruebas. Sin esto los
/// identificadores persistidos serían impredecibles y ninguna prueba podría
/// afirmar sobre ellos, igual que ocurriría con las fechas sin el reloj (T015).
abstract interface class IdGenerator {
  String generate();
}

class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const _uuid = Uuid();

  @override
  String generate() => _uuid.v4();
}

@Riverpod(keepAlive: true)
IdGenerator idGenerator(Ref ref) => const UuidIdGenerator();
