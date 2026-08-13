import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Único lugar del código donde vive el `switch` exhaustivo sobre
/// `AsyncValue` (FR-020). Resuelve las cuatro situaciones de una pantalla:
/// cargando, con datos, vacía y con error. El caso vacío vive **dentro** de la
/// rama de datos, no como un cuarto estado de `AsyncValue`: `isEmpty` decide,
/// a partir de los datos ya cargados, si se muestra [empty] o [data].
class AsyncScaffoldBody<T> extends StatelessWidget {
  const AsyncScaffoldBody({
    required this.value,
    required this.data,
    required this.isEmpty,
    required this.empty,
    this.loading,
    this.error,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;
  final bool Function(T data) isEmpty;
  final WidgetBuilder empty;
  final WidgetBuilder? loading;
  final Widget Function(BuildContext context, Object error, StackTrace stackTrace)?
      error;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData<T>(:final value) =>
        isEmpty(value) ? empty(context) : data(context, value),
      // Un provider que se reconstruye entero por un `ref.watch` sobre algo
      // que cambia seguido (p. ej. el progreso de una descarga) pasa por
      // `AsyncLoading` en cada reconstrucción aunque ya tuviera datos
      // (Riverpod los conserva vía `copyWithPrevious`). Sin esta rama, la
      // pantalla parpadeaba entre el spinner y el contenido en cada tick de
      // progreso (bug real, ajustes de modelo durante una descarga) — el
      // valor previo sigue siendo válido mientras se resuelve el nuevo.
      AsyncLoading<T>() when value.hasValue =>
        isEmpty(value.requireValue) ? empty(context) : data(context, value.requireValue),
      AsyncError<T>(:final error, :final stackTrace) =>
        (this.error ?? _defaultError)(context, error, stackTrace),
      AsyncLoading<T>() => (loading ?? _defaultLoading)(context),
    };
  }

  static Widget _defaultLoading(BuildContext context) =>
      const Center(child: CircularProgressIndicator());

  static Widget _defaultError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      Center(child: Text('Ha ocurrido un error: $error'));
}
