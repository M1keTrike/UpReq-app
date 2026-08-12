import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/features/transcription/data/model_download_client.dart';
import 'package:up_req/features/transcription/domain/contracts/model_repository.dart';
import 'package:up_req/features/transcription/domain/contracts/transcriber.dart';

/// Doble de `HttpClientAdapter`: nunca abre una conexión real. Cada prueba
/// encola exactamente la respuesta que necesita.
class _ScriptedAdapter implements HttpClientAdapter {
  final _scripts = <Future<ResponseBody> Function()>[];

  void enqueue(Future<ResponseBody> Function() script) => _scripts.add(script);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _scripts.removeAt(0)();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late String destinationPath;
  late _ScriptedAdapter adapter;
  late ModelDownloadClient client;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('model-download-test');
    destinationPath = '${tempDir.path}${Platform.pathSeparator}ggml-small.bin';
    adapter = _ScriptedAdapter();
    client = ModelDownloadClient(
      dio: Dio()..httpClientAdapter = adapter,
      resolvePath: (_) async => destinationPath,
      resolveUrl: (_) => Uri.parse('https://example.invalid/ggml-small.bin'),
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('una descarga fallida no deja ningún modelo utilizable (FR-022)', () async {
    adapter.enqueue(() async {
      final controller = StreamController<Uint8List>();
      controller.add(Uint8List.fromList(List.filled(10, 1)));
      Future.microtask(() => controller.addError(Exception('conexión perdida')));
      return ResponseBody(controller.stream, 200);
    });

    final progress = await client.download(TranscriptionModel.small).toList();

    expect(progress.last.state, DownloadState.failed);
    expect(File(destinationPath).existsSync(), isFalse);
    expect(File('$destinationPath.part').existsSync(), isFalse);
  });

  test('una descarga cancelada no deja ningún modelo utilizable (FR-022)', () async {
    final chunkController = StreamController<Uint8List>();
    adapter.enqueue(() async => ResponseBody(chunkController.stream, 200));

    final events = <DownloadProgress>[];
    final subscription = client.download(TranscriptionModel.small).listen(events.add);

    // Deja que arranque y escriba el primer trozo antes de cancelar, para
    // que exista contenido parcial que la cancelación deba limpiar.
    chunkController.add(Uint8List.fromList(List.filled(10, 2)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    client.cancel(TranscriptionModel.small);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();
    await chunkController.close();

    expect(events.map((p) => p.state), contains(DownloadState.cancelled));
    expect(File(destinationPath).existsSync(), isFalse);
    expect(File('$destinationPath.part').existsSync(), isFalse);
  });

  test('reintentar sobrescribe el .part en vez de anexar contenido viejo', () async {
    // Simula un `.part` con contenido viejo, como el que dejaría un
    // intento anterior sin terminar de limpiarse.
    File('$destinationPath.part')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(999, 9));

    final content = Uint8List.fromList(List.filled(20, 7));
    adapter.enqueue(() async {
      return ResponseBody.fromBytes(
        content,
        200,
        headers: {
          Headers.contentLengthHeader: ['${content.length}'],
        },
      );
    });

    final progress = await client.download(TranscriptionModel.small).toList();

    expect(progress.last.state, DownloadState.done);
    expect(await File(destinationPath).readAsBytes(), content);
    expect(File('$destinationPath.part').existsSync(), isFalse);
  });
}
