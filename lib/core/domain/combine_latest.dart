import 'dart:async';

/// Combina dos streams en uno solo que emite cada vez que cualquiera de los
/// dos emite, una vez que ambos han emitido al menos un valor. Sin
/// dependencia externa (`rxdart` no está en el árbol de dependencias):
/// se usa para los providers de detalle que combinan varias consultas de
/// drift en un único stream, evitando multiplicar las re-consultas que
/// provoca la invalidación por tabla (decisión 9 de research.md).
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combine,
) {
  late final StreamController<R> controller;
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;

  void emit() {
    if (hasA && hasB) {
      try {
        controller.add(combine(latestA as A, latestB as B));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }
  }

  controller = StreamController<R>.broadcast(
    onListen: () {
      subA = a.listen(
        (value) {
          latestA = value;
          hasA = true;
          emit();
        },
        onError: controller.addError,
      );
      subB = b.listen(
        (value) {
          latestB = value;
          hasB = true;
          emit();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );

  return controller.stream;
}
