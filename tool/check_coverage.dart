// Lee coverage/lcov.info y falla si la cobertura de lib/features/*/domain/
// baja del umbral (80% por defecto, o el que indique --min).
import 'dart:io';

void main(List<String> args) {
  var minPercent = 80.0;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--min' && i + 1 < args.length) {
      minPercent = double.parse(args[i + 1]);
    }
  }

  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    stderr.writeln(
      'No se encontró coverage/lcov.info. Ejecuta `flutter test --coverage` primero.',
    );
    exitCode = 2;
    return;
  }

  final domainPattern = RegExp(r'lib[\\/]features[\\/][^\\/]+[\\/]domain[\\/]');

  var totalLines = 0;
  var hitLines = 0;
  var inDomainFile = false;
  final perFile = <String, _FileCoverage>{};
  String? currentFile;

  for (final rawLine in lcovFile.readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      // El código generado por riverpod_generator (*.g.dart) no se prueba
      // directamente: son fábricas de providers mecánicas sin lógica de
      // dominio propia (delegan en la clase/función que anota `@riverpod`,
      // esa sí medida). Incluirlo en la puerta de cobertura penaliza al
      // dominio por líneas que ninguna prueba unitaria razonable ejercita
      // por sí solas, sin que eso refleje una laguna real de pruebas.
      final isGenerated = currentFile.endsWith('.g.dart');
      inDomainFile = !isGenerated && domainPattern.hasMatch(currentFile);
      if (inDomainFile) {
        perFile[currentFile] = _FileCoverage();
      }
    } else if (line.startsWith('DA:') && inDomainFile && currentFile != null) {
      final parts = line.substring(3).split(',');
      final hits = int.parse(parts[1]);
      totalLines++;
      perFile[currentFile]!.total++;
      if (hits > 0) {
        hitLines++;
        perFile[currentFile]!.hit++;
      }
    } else if (line == 'end_of_record') {
      inDomainFile = false;
      currentFile = null;
    }
  }

  if (totalLines == 0) {
    stderr.writeln(
      'No se encontraron líneas instrumentadas bajo lib/features/*/domain/.',
    );
    exitCode = 1;
    return;
  }

  final percent = hitLines / totalLines * 100;
  stdout.writeln(
    'Cobertura de domain: ${percent.toStringAsFixed(2)}% '
    '($hitLines/$totalLines líneas) — umbral $minPercent%',
  );

  if (percent < minPercent) {
    stderr.writeln('FALLO: cobertura por debajo del umbral.');
    final sorted = perFile.entries.toList()
      ..sort((a, b) => a.value.percent.compareTo(b.value.percent));
    for (final entry in sorted) {
      if (entry.value.percent < minPercent) {
        stderr.writeln(
          '  - ${entry.key}: ${entry.value.percent.toStringAsFixed(2)}% '
          '(${entry.value.hit}/${entry.value.total})',
        );
      }
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('OK: cobertura de domain por encima del umbral.');
}

class _FileCoverage {
  int total = 0;
  int hit = 0;

  double get percent => total == 0 ? 100.0 : hit / total * 100;
}
