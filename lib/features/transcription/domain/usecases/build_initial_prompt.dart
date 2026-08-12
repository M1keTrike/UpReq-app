import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:up_req/features/glossary/domain/entities/glossary_term.dart';

part 'build_initial_prompt.g.dart';

/// FR-014: convierte el glosario del proyecto en el `initialPrompt` que
/// ambas pasadas de Whisper reciben como apoyo léxico. Función pura: sin
/// términos devuelve cadena vacía en vez de lanzar o inventar contenido.
final class BuildInitialPrompt {
  const BuildInitialPrompt();

  String call(List<GlossaryTerm> terms) {
    if (terms.isEmpty) return '';
    return terms.map((term) => term.term).join(', ');
  }
}

// keepAlive: se lee desde StartLivePass (T080), leído a su vez desde
// ActiveCaptureNotifier (keepAlive); riverpod_lint exige que un provider
// keepAlive no dependa de uno autoDispose.
@Riverpod(keepAlive: true)
BuildInitialPrompt buildInitialPrompt(Ref ref) => const BuildInitialPrompt();
