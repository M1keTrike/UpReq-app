// Auditoría de importaciones (constitución, Principio I: "domain sin Flutter
// ni infraestructura"; plan.md, "Confinamiento de las dependencias
// nativas"). Verifica, en orden:
//
// 1. Ningún archivo bajo lib/**/domain/ importa package:flutter.
// 2. Cada paquete de infraestructura nativa se importa desde como máximo un
//    archivo de lib/, el declarado en plan.md. Igual que con `dio`
//    (tool/check_no_network_deps.dart), "cero" es válido antes de que la
//    tarea que lo cablea exista todavía; "dos o más" nunca lo es.
// 3. (T108, Fase 9) Ningún archivo bajo lib/**/presentation/ importa
//    package:drift: los widgets consumen entidades de dominio, nunca filas
//    de la base.
// 4. (T108, Fase 9) El único archivo autorizado a importar `package:dio`
//    (verificado en el punto 2) nunca llama a `.post(`, `.put(` ni
//    construye `FormData`: la única operación de red del incremento es un
//    `GET` de descarga (research.md, decisión 3). Es la verificación
//    estructural de que el audio jamás sale del dispositivo (Principio II).
import 'dart:io';

/// Paquete -> archivo único declarado en plan.md (Project Structure).
const _singleImporterPackages = <String, String>{
  'record': 'lib/features/recordings/data/record_audio_recorder.dart',
  'whisper_ggml': 'lib/features/transcription/data/whisper_transcriber.dart',
  'just_audio': 'lib/features/recordings/data/just_audio_player.dart',
  'dio': 'lib/features/transcription/data/model_download_client.dart',
};

final _dioVerbPattern = RegExp(r'\.post\(|\.put\(|FormData');

Future<void> main() async {
  final libDir = Directory('lib');
  var failed = false;

  final domainFlutterImports = <String>[];
  final presentationDriftImports = <String>[];
  final importersByPackage = <String, List<String>>{
    for (final name in _singleImporterPackages.keys) name: [],
  };
  var dioClientHasWriteVerb = false;

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final content = await entity.readAsString();

    if (path.contains('/domain/') && RegExp('''import\\s+['"]package:flutter/''').hasMatch(content)) {
      domainFlutterImports.add(path);
    }

    if (path.contains('/presentation/') && RegExp('''import\\s+['"]package:drift/''').hasMatch(content)) {
      presentationDriftImports.add(path);
    }

    for (final name in _singleImporterPackages.keys) {
      if (RegExp('''import\\s+['"]package:$name/''').hasMatch(content)) {
        importersByPackage[name]!.add(path);
      }
    }

    if (path == _singleImporterPackages['dio'] && _dioVerbPattern.hasMatch(content)) {
      dioClientHasWriteVerb = true;
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

  if (presentationDriftImports.isNotEmpty) {
    failed = true;
    stderr.writeln('FALLO: archivos de presentation/ que importan package:drift:');
    for (final f in presentationDriftImports..sort()) {
      stderr.writeln('  - $f');
    }
  } else {
    stdout.writeln('OK: ningún archivo de presentation/ importa package:drift.');
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

  if (dioClientHasWriteVerb) {
    failed = true;
    stderr.writeln(
      'FALLO: ${_singleImporterPackages['dio']} usa .post(/.put(/FormData. '
      'La única operación de red permitida es un GET de descarga (FR-021).',
    );
  } else {
    stdout.writeln('OK: el cliente de dio solo hace GET de descarga; ningún post/put/FormData.');
  }

  if (failed) {
    exitCode = 1;
  }
}
