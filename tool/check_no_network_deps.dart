// Verificación estructural de FR-021 (incremento 2, sustituye a FR-019 del
// incremento 1): la única dependencia de red permitida en la clausura de
// `dependencies:` es `dio`, y `package:dio` solo puede importarse desde
// exactamente un archivo de `lib/` — el cliente de descarga del modelo.
//
// Se restringe a la clausura de `dependencies:` (no `dev_dependencies:`),
// porque eso es exactamente lo que termina en el binario compilado: el
// toolchain de build (build_runner, drift_dev...) trae paquetes de red
// propios que nunca llegan a la app y no deben bloquear esta puerta.
//
// Excepción documentada: `riverpod` (dependencia dura de `flutter_riverpod`,
// versión fijada por la constitución) declara `test` como dependencia normal
// —no dev— porque expone `ProviderContainer.test()`. Eso arrastra
// `web_socket_channel`/`web_socket` de forma transitiva sin que la app los
// use jamás en tiempo de ejecución. Este script no los trata como paquete
// vetado *solo* cuando su única vía de entrada es exactamente esa: si dejan
// de ser alcanzables al excluir el borde `test`, es que entraron por otra
// vía y sí deben bloquear CI.
import 'dart:convert';
import 'dart:io';

const _bannedPackages = <String>{
  'http',
  'http_client',
  'cronet_http',
  'cupertino_http',
  'web_socket_channel',
  'web_socket',
  'grpc',
  'socket_io_client',
  'connectivity_plus',
};

/// `dio` es la única excepción de red constitucional (research.md, decisión
/// 3). Entra en la clausura de `dependencies:` sin bloquear esta puerta,
/// pero su número de importadores en `lib/` sí se verifica más abajo.
const _networkExceptionPackage = 'dio';

/// Paquetes vetados que SOLO se toleran si su único camino de entrada es la
/// arista `riverpod -> test` documentada arriba. Cualquier otro paquete vetado
/// bloquea CI sin excepción.
const _tolerableViaRiverpodTest = <String>{
  'web_socket_channel',
  'web_socket',
};

/// Segunda excepción, del incremento 2: `wakelock_plus` (research.md,
/// `wakelock_plus` mantiene la pantalla activa durante la captura, T045)
/// depende de `package_info_plus`, que a su vez depende de `http` — pero
/// verificado en su código fuente, ese import solo existe en
/// `package_info_plus_windows.dart` y `package_info_plus_web.dart`. Ninguna
/// de las dos rutas se ejecuta en Android/iOS, las plataformas de producto
/// (Technical Context de plan.md); es el mismo patrón que la tolerancia de
/// `riverpod -> test` de arriba, un paquete alcanzable en el grafo pero
/// inalcanzable en el runtime real de la app.
const _tolerableViaPackageInfoPlus = <String>{'http'};

Future<void> main() async {
  final result = await Process.run('dart', ['pub', 'deps', '--json']);
  if (result.exitCode != 0) {
    stderr.writeln('No se pudo ejecutar `dart pub deps --json`:\n${result.stderr}');
    exitCode = 2;
    return;
  }

  final doc = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final packages = doc['packages'] as List;
  final byName = <String, List<String>>{
    for (final p in packages)
      (p as Map<String, dynamic>)['name'] as String:
          (p['dependencies'] as List).cast<String>(),
  };

  final root = packages.firstWhere(
    (p) => (p as Map<String, dynamic>)['kind'] == 'root',
  ) as Map<String, dynamic>;
  final mainDirect = (root['directDependencies'] as List).cast<String>();

  if (!mainDirect.contains(_networkExceptionPackage)) {
    stderr.writeln(
      "FALLO: se esperaba que 'dio' fuera dependencia directa (la excepción "
      'de red única, research.md decisión 3) y no aparece en dependencies:.',
    );
    exitCode = 1;
    return;
  }

  final withAll = _closure(mainDirect, byName, skip: const {});
  final withoutTest = _closure(mainDirect, byName, skip: const {'test'});
  final withoutPackageInfoPlus =
      _closure(mainDirect, byName, skip: const {'package_info_plus'});

  final found = withAll.where(_bannedPackages.contains).toList()..sort();
  final blocking = <String>[];
  final tolerated = <String>[];

  for (final name in found) {
    final onlyViaTest =
        _tolerableViaRiverpodTest.contains(name) && !withoutTest.contains(name);
    final onlyViaPackageInfoPlus = _tolerableViaPackageInfoPlus.contains(name) &&
        !withoutPackageInfoPlus.contains(name);
    if (onlyViaTest || onlyViaPackageInfoPlus) {
      tolerated.add(name);
    } else {
      blocking.add(name);
    }
  }

  if (tolerated.isNotEmpty) {
    stdout.writeln(
      'Toleradas (solo alcanzables vía riverpod -> test o wakelock_plus -> '
      'package_info_plus, nunca ejecutadas en runtime): ${tolerated.join(', ')}',
    );
  }

  // "Exactamente un archivo" es el estado final del incremento (a partir de
  // T101, el cliente de descarga del modelo). Antes de esa tarea, cero
  // importadores es válido: lo único que esta puerta no tolera nunca es un
  // SEGUNDO importador, que es el modo de falla real que motiva el gate
  // (research.md, decisión 3).
  final dioImporters = await _findDioImporters();
  if (dioImporters.length > 1) {
    stderr.writeln(
      'FALLO: package:dio debe importarse desde como máximo UN archivo de '
      'lib/ (el cliente de descarga del modelo). Se encontraron '
      '${dioImporters.length}:',
    );
    for (final f in dioImporters) {
      stderr.writeln('  - $f');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    dioImporters.isEmpty
        ? 'OK: package:dio aún sin importador (pendiente del cliente de descarga).'
        : 'OK: package:dio se importa desde un único archivo: ${dioImporters.single}',
  );

  if (blocking.isEmpty) {
    stdout.writeln(
      'OK: ninguna dependencia de red prohibida en la clausura de dependencies: '
      "salvo la excepción única 'dio' (FR-021).",
    );
    return;
  }

  stderr.writeln(
    'FALLO: se encontraron dependencias de red prohibidas por FR-021:',
  );
  for (final name in blocking) {
    stderr.writeln('  - $name');
  }
  exitCode = 1;
}

Future<List<String>> _findDioImporters() async {
  final libDir = Directory('lib');
  final importers = <String>[];
  final pattern = RegExp('''import\\s+['"]package:dio/''');

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = await entity.readAsString();
    if (pattern.hasMatch(content)) {
      importers.add(entity.path.replaceAll('\\', '/'));
    }
  }
  importers.sort();
  return importers;
}

Set<String> _closure(
  List<String> roots,
  Map<String, List<String>> byName, {
  required Set<String> skip,
}) {
  final visited = <String>{};
  final queue = List<String>.of(roots);
  while (queue.isNotEmpty) {
    final name = queue.removeLast();
    if (skip.contains(name)) continue;
    if (!visited.add(name)) continue;
    queue.addAll(byName[name] ?? const []);
  }
  return visited;
}
