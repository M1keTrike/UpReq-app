import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';
import 'package:up_req/core/widgets/async_scaffold_body.dart';
import 'package:up_req/features/transcription/presentation/transcript_section.dart';

import '../domain/entities/recording.dart';
import 'live_mark_list.dart';
import 'recording_detail_provider.dart';
import 'recording_playback_notifier.dart';

/// Detalle de grabación (ui-contracts.md, pantalla 3): reproductor, marcas
/// y transcripción. FR-017: el reproductor funciona exista o no
/// transcripción, porque `LiveMarkList` y `TranscriptSection` son secciones
/// autocontenidas que no dependen la una de la otra.
class RecordingDetailScreen extends ConsumerWidget {
  const RecordingDetailScreen({required this.recordingId, super.key});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingDetailProvider(recordingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Grabación')),
      body: AsyncScaffoldBody<RecordingDetailState>(
        value: state,
        isEmpty: (_) => false,
        empty: (_) => const SizedBox.shrink(),
        data: (context, data) => _RecordingDetailView(
          recordingId: recordingId,
          recording: data.recording,
          isReadOnly: data.isReadOnly,
        ),
      ),
    );
  }
}

class _RecordingDetailView extends StatelessWidget {
  const _RecordingDetailView({
    required this.recordingId,
    required this.recording,
    required this.isReadOnly,
  });

  final String recordingId;
  final Recording recording;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Grabación · ${_statusLabel(recording.status)}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PlaybackControls(recordingId: recordingId, durationMs: recording.durationMs),
        const Divider(height: 32),
        Text('Marcas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LiveMarkList(recordingId: RecordingId(recordingId), isReadOnly: isReadOnly),
        const Divider(height: 32),
        Text('Transcripción', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TranscriptSection(recordingId: recordingId),
      ],
    );
  }

  static String _statusLabel(RecordingStatus status) => switch (status) {
        RecordingStatus.recording => 'En curso',
        RecordingStatus.stopped => 'Detenida',
        RecordingStatus.interrupted => 'Interrumpida',
      };
}

class _PlaybackControls extends ConsumerWidget {
  const _PlaybackControls({required this.recordingId, required this.durationMs});

  final String recordingId;
  final int durationMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(recordingPlaybackProvider(recordingId));
    final notifier = ref.read(recordingPlaybackProvider(recordingId).notifier);

    return Row(
      children: [
        IconButton(
          key: const Key('playback-toggle-button'),
          icon: Icon(playback.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => playback.isPlaying ? notifier.pause() : notifier.play(),
        ),
        Text(
          '${_formatDuration(playback.position)} / ${_formatDuration(Duration(milliseconds: durationMs))}',
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
