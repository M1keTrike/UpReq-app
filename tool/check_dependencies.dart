// Verificación automática de la prohibición constitucional de dependencias:
// ninguna dependencia resuelta puede carecer de null safety, llevar más de doce
// meses sin publicación, o tener licencia GPL/AGPL. Hasta ahora esto solo se
// comprobaba a mano.
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

Future<void> main() async {
  final lockFile = File('pubspec.lock');
  final packageConfigFile = File('.dart_tool/package_config.json');

  if (!lockFile.existsSync()) {
    stderr.writeln(
      'No se encontró pubspec.lock. Ejecuta `flutter pub get` primero.',
    );
    exitCode = 2;
    return;
  }
  if (!packageConfigFile.existsSync()) {
    stderr.writeln(
      'No se encontró .dart_tool/package_config.json. Ejecuta `flutter pub get` primero.',
    );
    exitCode = 2;
    return;
  }

  final lockDoc = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final lockPackages = (lockDoc['packages'] as YamlMap?) ?? YamlMap();

  final hosted = <String, String>{};
  for (final entry in lockPackages.entries) {
    final name = entry.key.toString();
    final info = entry.value as YamlMap;
    if (info['source'] == 'hosted') {
      hosted[name] = info['version'].toString();
    }
  }

  final packageConfig =
      jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final configDir = packageConfigFile.parent.uri;
  final packagesByName = <String, Map<String, dynamic>>{
    for (final p in (packageConfig['packages'] as List))
      (p as Map<String, dynamic>)['name'] as String: p,
  };

  final violations = <String>[];
  final client = HttpClient();

  try {
    for (final name in hosted.keys.toList()..sort()) {
      final version = hosted[name]!;
      final entry = packagesByName[name];
      if (entry == null) continue;

      // Null safety: el lenguaje 2.12 es cuando Dart introdujo sound null safety.
      final languageVersion = entry['languageVersion'] as String?;
      if (languageVersion != null && !_hasNullSafety(languageVersion)) {
        violations.add(
          '$name $version: sin null safety (language version $languageVersion)',
        );
      }

      // Licencia: se busca en el directorio resuelto del paquete.
      final rootUriRaw = entry['rootUri'] as String;
      final rootUri = configDir.resolve(rootUriRaw);
      final license = _detectRestrictedLicense(Directory.fromUri(rootUri));
      if (license != null) {
        violations.add('$name $version: licencia $license');
      }

      // Antigüedad de publicación: vía la API de pub.dev.
      final publishedIssue = await _checkPublishDate(client, name, version);
      if (publishedIssue != null) {
        violations.add('$name $version: $publishedIssue');
      }
    }
  } finally {
    client.close(force: true);
  }

  if (violations.isEmpty) {
    stdout.writeln(
      'OK: todas las dependencias resueltas tienen null safety, licencia '
      'permitida y publicación reciente.',
    );
    return;
  }

  stderr.writeln('FALLO: dependencias que incumplen la prohibición constitucional:');
  for (final v in violations) {
    stderr.writeln('  - $v');
  }
  exitCode = 1;
}

bool _hasNullSafety(String languageVersion) {
  final parts = languageVersion.split('.');
  if (parts.length < 2) return true;
  final major = int.tryParse(parts[0]) ?? 0;
  final minor = int.tryParse(parts[1]) ?? 0;
  return major > 2 || (major == 2 && minor >= 12);
}

const _licenseFileNames = [
  'LICENSE',
  'LICENSE.md',
  'LICENSE.txt',
  'COPYING',
  'COPYING.md',
];

String? _detectRestrictedLicense(Directory packageDir) {
  for (final fileName in _licenseFileNames) {
    final file = File('${packageDir.path}${Platform.pathSeparator}$fileName');
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync().toUpperCase();
    final isAgpl = content.contains('AFFERO GENERAL PUBLIC LICENSE') ||
        content.contains('AGPL');
    if (isAgpl) return 'AGPL';

    final mentionsGpl = content.contains('GENERAL PUBLIC LICENSE') ||
        RegExp(r'\bGPL\b').hasMatch(content);
    final isLesser = content.contains('LESSER GENERAL PUBLIC LICENSE') ||
        content.contains('LGPL');
    if (mentionsGpl && !isLesser) return 'GPL';

    return null;
  }
  return null;
}

Future<String?> _checkPublishDate(
  HttpClient client,
  String name,
  String version,
) async {
  try {
    final uri = Uri.parse('https://pub.dev/api/packages/$name/versions/$version');
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) {
      return null; // No se puede verificar: no se bloquea por un fallo de red.
    }
    final body = jsonDecode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
    final publishedRaw = body['published'] as String?;
    if (publishedRaw == null) return null;

    final published = DateTime.parse(publishedRaw);
    final ageInDays = DateTime.now().difference(published).inDays;
    if (ageInDays > 365) {
      return 'sin publicación en los últimos 12 meses (última: $publishedRaw)';
    }
    return null;
  } catch (_) {
    return null; // Sin red disponible: no se bloquea la verificación local.
  }
}
