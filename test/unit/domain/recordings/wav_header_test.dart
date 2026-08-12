import 'package:flutter_test/flutter_test.dart';
import 'package:up_req/features/recordings/domain/wav_header_repair.dart';

void main() {
  group('WavHeaderRepair.plan', () {
    test('calcula los tamaños para un archivo con tramas completas a 16 kHz mono', () {
      // 16000 muestras/s * 2 bytes/muestra * 2 s = 64000 bytes de datos.
      const headerBytes = 44;
      const dataBytes = 64000;
      final plan = WavHeaderRepair.plan(
        fileLengthBytes: headerBytes + dataBytes,
        sampleRate: 16000,
        channels: 1,
      );

      expect(plan.dataChunkSize, dataBytes);
      expect(plan.riffChunkSize, 36 + dataBytes);
      expect(plan.durationMs, 2000);
    });

    test('archivo vacío (solo cabecera o ni eso) produce tamaños en cero', () {
      final planNoHeader = WavHeaderRepair.plan(
        fileLengthBytes: 0,
        sampleRate: 16000,
        channels: 1,
      );
      expect(planNoHeader.dataChunkSize, 0);
      expect(planNoHeader.riffChunkSize, 36);
      expect(planNoHeader.durationMs, 0);

      final planOnlyHeader = WavHeaderRepair.plan(
        fileLengthBytes: 44,
        sampleRate: 16000,
        channels: 1,
      );
      expect(planOnlyHeader.dataChunkSize, 0);
      expect(planOnlyHeader.riffChunkSize, 36);
      expect(planOnlyHeader.durationMs, 0);
    });

    test('trama incompleta al final se descarta, no se cuenta como muestra parcial', () {
      // 100 muestras completas (200 bytes) más un byte suelto de una trama
      // que no llegó a completarse antes del corte.
      final plan = WavHeaderRepair.plan(
        fileLengthBytes: 44 + 200 + 1,
        sampleRate: 16000,
        channels: 1,
      );

      expect(plan.dataChunkSize, 200);
      expect(plan.riffChunkSize, 236);
      // 100 muestras / 16000 Hz = 6.25 ms, truncado a 6.
      expect(plan.durationMs, 6);
    });

    test('estéreo: el ancho de trama es el doble', () {
      final plan = WavHeaderRepair.plan(
        fileLengthBytes: 44 + 4000,
        sampleRate: 16000,
        channels: 2,
      );

      // 4000 bytes / (2 canales * 2 bytes) = 1000 muestras por canal.
      expect(plan.dataChunkSize, 4000);
      expect(plan.durationMs, 62);
    });
  });
}
