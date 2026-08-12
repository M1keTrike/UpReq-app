import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';

import '../domain/entities/model_entry.dart';
import 'model_mutations.dart';
import 'model_settings_provider.dart';

/// Ajustes del modelo de transcripción (ui-contracts.md, pantalla 5). La
/// única pantalla de todo el proyecto que toca la red: descarga manual,
/// observable y cancelable, con progreso indeterminado cuando el servidor
/// no informa `Content-Length` (T099).
class ModelSettingsScreen extends ConsumerWidget {
  const ModelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Modelos de transcripción')),
      body: AsyncScaffoldBody<ModelSettingsState>(
        value: state,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (data.pendingTranscripts > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${data.pendingTranscripts} transcripción(es) esperando el modelo.',
                  key: const Key('pending-transcripts-count'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            for (final entry in data.models) _ModelTile(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends ConsumerWidget {
  const _ModelTile({required this.entry});

  final ModelEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      key: Key('model-tile-${entry.model.name}'),
      child: ListTile(
        title: Text(entry.label),
        subtitle: _StatusLabel(entry: entry),
        trailing: _trailing(ref),
      ),
    );
  }

  Widget? _trailing(WidgetRef ref) {
    return switch (entry.status) {
      ModelStatus.downloading => IconButton(
          key: Key('cancel-download-${entry.model.name}'),
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar descarga',
          onPressed: () => runCancelModelDownload(ref, entry.model),
        ),
      ModelStatus.available => const Icon(Icons.check_circle_outline),
      ModelStatus.notDownloaded || ModelStatus.failed => IconButton(
          key: Key('download-model-${entry.model.name}'),
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Descargar',
          onPressed: () => runDownloadModel(ref, entry.model),
        ),
    };
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.entry});

  final ModelEntry entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry.status) {
      ModelStatus.notDownloaded => const Text('No descargado'),
      ModelStatus.downloading => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: LinearProgressIndicator(
            key: const Key('download-progress'),
            // `null` -> barra indeterminada. No se inventa un porcentaje
            // cuando el servidor no informa Content-Length (T099).
            value: entry.progress,
          ),
        ),
      ModelStatus.available => const Text('Disponible'),
      ModelStatus.failed => Text(
          'La descarga falló',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    };
  }
}
