// Verificación automática del anclaje (constitución v1.3.0, Principio I,
// viñeta "Verificación automática del anclaje"): compara las versiones
// resueltas en pubspec.lock contra las que la constitución ancla de forma
// EXACTA, para los paquetes donde el desajuste ya ocurrió una vez sin que
// nada lo detectara — drift declaró 2.34.3 en el documento mientras el
// proyecto resolvía 2.34.0 durante todo el incremento 1.
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Paquete -> versión exacta que fija la constitución v1.3.0. Los cuatro de
/// Riverpod y drift: son los que el documento ancla con un número exacto, no
/// con un rango `^`.
const _pinnedByConstitution = <String, String>{
  'flutter_riverpod': '3.3.2',
  'riverpod_annotation': '4.0.3',
  'riverpod_generator': '4.0.4',
  'riverpod_lint': '3.1.4',
  'drift': '2.34.0',
};

void main() {
  final lockFile = File('pubspec.lock');
  if (!lockFile.existsSync()) {
    stderr.writeln('No se encontró pubspec.lock. Ejecuta `flutter pub get` primero.');
    exitCode = 2;
    return;
  }

  final lockDoc = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final packages = (lockDoc['packages'] as YamlMap?) ?? YamlMap();

  final mismatches = <String>[];
  final missing = <String>[];

  for (final entry in _pinnedByConstitution.entries) {
    final info = packages[entry.key] as YamlMap?;
    if (info == null) {
      missing.add(entry.key);
      continue;
    }
    final resolved = info['version'].toString();
    if (resolved != entry.value) {
      mismatches.add(
        '${entry.key}: constitución ancla ${entry.value}, pubspec.lock resuelve $resolved',
      );
    }
  }

  if (missing.isNotEmpty) {
    stderr.writeln('FALLO: paquetes anclados por la constitución ausentes de pubspec.lock:');
    for (final name in missing) {
      stderr.writeln('  - $name');
    }
    exitCode = 1;
    return;
  }

  if (mismatches.isNotEmpty) {
    stderr.writeln(
      'FALLO: desajuste entre el anclaje declarado en la constitución y '
      'pubspec.lock:',
    );
    for (final m in mismatches) {
      stderr.writeln('  - $m');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'OK: las versiones ancladas por la constitución coinciden con pubspec.lock '
    '(${_pinnedByConstitution.keys.join(', ')}).',
  );
}
