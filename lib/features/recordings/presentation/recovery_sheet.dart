import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/recording.dart';
import 'recording_mutations.dart';

/// Hoja modal de recuperación (ui-contracts.md, pantalla 4). No es una ruta:
/// existe mientras exista la condición que la justifica. **No se puede
/// descartar sin elegir**: las dos acciones son explícitas y ninguna es la
/// predeterminada — cerrarla sin elegir dejaría el audio en un limbo que la
/// siguiente apertura volvería a preguntar.
Future<void> showRecoverySheet(
  BuildContext context,
  WidgetRef ref, {
  required Recording interrupted,
  required bool canResume,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (sheetContext) {
      return PopScope(
        canPop: false,
        child: _RecoverySheetContent(interrupted: interrupted, canResume: canResume),
      );
    },
  );
}

class _RecoverySheetContent extends ConsumerWidget {
  const _RecoverySheetContent({required this.interrupted, required this.canResume});

  final Recording interrupted;
  final bool canResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = interrupted.durationMs ~/ 1000;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grabación interrumpida', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              seconds > 0
                  ? 'Se conservó el audio capturado hasta el corte (~$seconds s). '
                      '¿Qué quieres hacer?'
                  : 'Se conservó el audio capturado hasta el corte. ¿Qué quieres hacer?',
            ),
            const SizedBox(height: 24),
            if (canResume)
              FilledButton(
                key: const Key('resume-recording-button'),
                onPressed: () => _resume(context, ref),
                child: const Text('Reanudar la grabación'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('close-interrupted-button'),
              onPressed: () => _closeKeeping(context, ref),
              child: const Text('Cerrar conservando lo capturado'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    try {
      await runResumeRecording(ref, interrupted.id);
    } catch (_) {
      // El estado de la Mutation ya refleja el fallo.
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _closeKeeping(BuildContext context, WidgetRef ref) async {
    try {
      await runCloseInterruptedRecording(ref, interrupted.id);
    } catch (_) {
      // El estado de la Mutation ya refleja el fallo.
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
