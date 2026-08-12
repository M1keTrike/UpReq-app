// Auditoría de importaciones (constitución, Principio I: "domain sin Flutter
// ni infraestructura"; plan.md, "Confinamiento de las dependencias
// nativas"). Verifica dos cosas:
//
// 1. Ningún archivo bajo lib/**/domain/ importa package:flutter.
// 2. Cada paquete de infraestructura nativa se importa desde como máximo un
//    archivo de lib/, el declarado en plan.md. Igual que con `dio`
//    (tool/check_no_network_deps.dart), "cero" es válido antes de que la
//    tarea que lo cablea exista todavía; "dos o más" nunca lo es.
import 'dart:io';

/// Paquete -> archivo único declarado en plan.md (Project Structure).
const _singleImporterPackages = <String, String>{
  'record': 'lib/features/recordings/data/record_audio_recorder.dart',
  'whisper_ggml': 'lib/features/transcription/data/whisper_transcriber.dart',
  'just_audio': 'lib/features/recordings/data/just_audio_player.dart',
};

Future<void> main() async {
  final libDir = Directory('lib');
  var failed = false;

  final domainFlutterImports = <String>[];
  final importersByPackage = <String, List<String>>{
    for (final name in _singleImporterPackages.keys) name: [],
  };

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final content = await entity.readAsString();

    if (path.contains('/domain/') && RegExp('''import\\s+['"]package:flutter/''').hasMatch(content)) {
      domainFlutterImports.add(path);
    }

    for (final name in _singleImporterPackages.keys) {
      if (RegExp('''import\\s+['"]package:$name/''').hasMatch(content)) {
        importersByPackage[name]!.add(path);
      }
    }
  }

  if (domainFlutterImports.isNotEmpty) {
    failed = true;
    stderr.writeln('FALLO: archivos de domain/ que importan package:flutter:');
    for (final f in domainFlutterImports..sort()) {
      stderr.writeln('  - $f');
    }
  } else {
    stdout.writeln('OK: ningún archivo de domain/ importa package:flutter.');
  }

  for (final entry in _singleImporterPackages.entries) {
    final importers = importersByPackage[entry.key]!..sort();
    if (importers.length > 1) {
      failed = true;
      stderr.writeln(
        'FALLO: package:${entry.key} debe importarse desde como máximo un '
        'archivo (${entry.value}). Se encontraron ${importers.length}:',
      );
      for (final f in importers) {
        stderr.writeln('  - $f');
      }
    } else if (importers.length == 1 && importers.single != entry.value) {
      failed = true;
      stderr.writeln(
        'FALLO: package:${entry.key} se importa desde ${importers.single}, '
        'pero plan.md declara ${entry.value} como su único importador.',
      );
    } else {
      stdout.writeln(
        importers.isEmpty
            ? 'OK: package:${entry.key} aún sin importador (pendiente de su tarea de datos).'
            : 'OK: package:${entry.key} se importa solo desde ${entry.value}.',
      );
    }
  }

  if (failed) {
    exitCode = 1;
  }
}
