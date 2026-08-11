// Verificación estructural de FR-019: ninguna dependencia de la app puede ser
// un paquete de red. Se restringe a la clausura de `dependencies:` (no
// `dev_dependencies:`), porque eso es exactamente lo que termina en el binario
// compilado: el toolchain de build (build_runner, drift_dev...) trae paquetes
// de red propios (p. ej. web_socket_channel para su build daemon) que nunca
// llegan a la app y no deben bloquear esta puerta.
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
  'dio',
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

/// Paquetes vetados que SOLO se toleran si su único camino de entrada es la
/// arista `riverpod -> test` documentada arriba. Cualquier otro paquete vetado
/// bloquea CI sin excepción.
const _tolerableViaRiverpodTest = <String>{
  'web_socket_channel',
  'web_socket',
};

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

  final withTest = _closure(mainDirect, byName, skip: const {});
  final withoutTest = _closure(mainDirect, byName, skip: const {'test'});

  final found = withTest.where(_bannedPackages.contains).toList()..sort();
  final blocking = <String>[];
  final tolerated = <String>[];

  for (final name in found) {
    final onlyViaTest =
        _tolerableViaRiverpodTest.contains(name) && !withoutTest.contains(name);
    if (onlyViaTest) {
      tolerated.add(name);
    } else {
      blocking.add(name);
    }
  }

  if (tolerated.isNotEmpty) {
    stdout.writeln(
      'Toleradas (solo alcanzables vía riverpod -> test, nunca ejecutadas '
      'en runtime): ${tolerated.join(', ')}',
    );
  }

  if (blocking.isEmpty) {
    stdout.writeln(
      'OK: ninguna dependencia de red bloqueante en la clausura de dependencies: (FR-019).',
    );
    return;
  }

  stderr.writeln(
    'FALLO: se encontraron dependencias de red prohibidas por FR-019:',
  );
  for (final name in blocking) {
    stderr.writeln('  - $name');
  }
  exitCode = 1;
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
