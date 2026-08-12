import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/contracts/wav_sink.dart';
import '../domain/wav_header_repair.dart';

part 'wav_writer.g.dart';

const _headerBytes = 44;

/// Escribe la cabecera RIFF de 44 bytes con los dos campos de tamaño en
/// cero, anexa las tramas PCM conforme llegan, y parchea ambos tamaños al
/// cerrar. Es lo que hace recuperable una grabación interrumpida
/// (research.md, decisión 4): un cierre inesperado deja el audio íntegro
/// detrás de una cabecera sin parchear.
///
/// Instancia única inyectada como `keepAlive`, igual que `AudioRecorder`: el
/// archivo abierto es un recurso de dispositivo que el notifier posee
/// mientras dura la captura.
class WavFileSink implements WavSink {
  RandomAccessFile? _file;
  int _sampleRate = 16000;
  int _channels = 1;
  int _bytesWritten = 0;

  @override
  Future<void> open(String relativePath, {int sampleRate = 16000, int channels = 1}) async {
    _sampleRate = sampleRate;
    _channels = channels;
    _bytesWritten = 0;

    final absolutePath = await _resolveAbsolutePath(relativePath);
    await File(absolutePath).parent.create(recursive: true);
    final file = File(absolutePath).openSync(mode: FileMode.write);
    file.writeFromSync(_buildHeader(riffChunkSize: 0, dataChunkSize: 0));
    _file = file;
  }

  @override
  Future<void> append(Uint8List pcmFrames) async {
    final file = _file;
    if (file == null) {
      throw StateError('WavFileSink.append llamado sin abrir el archivo primero.');
    }
    // Deja que una excepción de E/S (p. ej. espacio agotado) se propague tal
    // cual: es el caso que activa StorageFullFailure en el notifier (T038a).
    file.writeFromSync(pcmFrames);
    _bytesWritten += pcmFrames.length;
  }

  @override
  Future<int> closeAndFinalize() async {
    final file = _file;
    if (file == null) {
      throw StateError('WavFileSink.closeAndFinalize llamado sin abrir el archivo primero.');
    }

    final plan = WavHeaderRepair.plan(
      fileLengthBytes: _headerBytes + _bytesWritten,
      sampleRate: _sampleRate,
      channels: _channels,
    );

    file.setPositionSync(4);
    file.writeFromSync(_uint32le(plan.riffChunkSize));
    file.setPositionSync(40);
    file.writeFromSync(_uint32le(plan.dataChunkSize));
    file.flushSync();
    file.closeSync();
    _file = null;

    return plan.durationMs;
  }

  Future<String> _resolveAbsolutePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}'
        '${relativePath.replaceAll('/', Platform.pathSeparator)}';
  }

  Uint8List _buildHeader({required int riffChunkSize, required int dataChunkSize}) {
    const bitsPerSample = 16;
    final byteRate = _sampleRate * _channels * bitsPerSample ~/ 8;
    final blockAlign = _channels * bitsPerSample ~/ 8;

    final bytes = ByteData(_headerBytes);
    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, riffChunkSize, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, _channels, Endian.little);
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, blockAlign, Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataChunkSize, Endian.little);

    return bytes.buffer.asUint8List();
  }

  Uint8List _uint32le(int value) {
    final bytes = ByteData(4)..setUint32(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }
}

@Riverpod(keepAlive: true)
WavSink wavSink(Ref ref) => WavFileSink();
