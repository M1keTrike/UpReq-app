import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:up_req/core/domain/ids.dart';

import '../domain/entities/live_mark.dart';
import 'active_capture_notifier.dart';
import 'recording_mutations.dart';

/// Barra de marcado en vivo (ui-contracts.md, pantalla 2 / FR-007).
/// Visible solo con captura activa y no interrumpida (FR-009). La
/// realimentación es pasiva y no bloqueante — nunca un diálogo, que
/// rompería el propósito de marcar sin interrumpir la conversación.
class LiveMarkBar extends StatelessWidget {
  const LiveMarkBar({required this.active, super.key});

  final ActiveCapture? active;

  @override
  Widget build(BuildContext context) {
    final capture = active;
    if (capture == null || capture.isInterrupted) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LivePartialZone(text: capture.livePartial),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MarkButton(
              recordingId: capture.id.value,
              kind: LiveMarkKind.requirement,
              icon: Icons.assignment_outlined,
              label: 'Posible requisito',
            ),
            _MarkButton(
              recordingId: capture.id.value,
              kind: LiveMarkKind.doubt,
              icon: Icons.help_outline,
              label: 'Duda',
            ),
            _MarkButton(
              recordingId: capture.id.value,
              kind: LiveMarkKind.quote,
              icon: Icons.format_quote_outlined,
              label: 'Cita textual',
            ),
          ],
        ),
      ],
    );
  }
}

/// Avance de la pasada en vivo (FR-012, T083a): el analista lee de reojo lo
/// que se acaba de decir y decide si marcar. Altura acotada, desplazamiento
/// automático hacia el texto más reciente, **sin interacción** (ni
/// seleccionable ni tocable) y ausente por completo cuando [text] es `null`
/// — nunca reserva espacio ni desplaza los botones de marcado.
class LivePartialZone extends StatefulWidget {
  const LivePartialZone({required this.text, super.key});

  final String? text;

  @override
  State<LivePartialZone> createState() => _LivePartialZoneState();
}

class _LivePartialZoneState extends State<LivePartialZone> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LivePartialZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    if (text == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        key: const Key('live-partial-zone'),
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
}

class _MarkButton extends ConsumerWidget {
  const _MarkButton({
    required this.recordingId,
    required this.kind,
    required this.icon,
    required this.label,
  });

  final String recordingId;
  final LiveMarkKind kind;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: label,
      child: IconButton.filledTonal(
        key: Key('mark-button-${kind.name}'),
        icon: Icon(icon),
        onPressed: () async {
          try {
            await runPlaceLiveMark(ref, RecordingId(recordingId), kind);
          } catch (_) {
            // El estado de la Mutation (MutationError) ya refleja el fallo.
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Marca colocada: $label'), duration: const Duration(milliseconds: 900)),
            );
          }
        },
      ),
    );
  }
}
