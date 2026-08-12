// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_marks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
/// lista del detalle de grabación (US5) y, indirectamente, el contador de
/// `ActiveCapture.marksPlaced` durante la captura.

@ProviderFor(liveMarks)
final liveMarksProvider = LiveMarksFamily._();

/// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
/// lista del detalle de grabación (US5) y, indirectamente, el contador de
/// `ActiveCapture.marksPlaced` durante la captura.

final class LiveMarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LiveMark>>,
          List<LiveMark>,
          Stream<List<LiveMark>>
        >
    with $FutureModifier<List<LiveMark>>, $StreamProvider<List<LiveMark>> {
  /// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
  /// lista del detalle de grabación (US5) y, indirectamente, el contador de
  /// `ActiveCapture.marksPlaced` durante la captura.
  LiveMarksProvider._({
    required LiveMarksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveMarksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveMarksHash();

  @override
  String toString() {
    return r'liveMarksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LiveMark>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LiveMark>> create(Ref ref) {
    final argument = this.argument as String;
    return liveMarks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveMarksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveMarksHash() => r'1b1c51331fee60b653d2c2d6deb857f2dbfd1d41';

/// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
/// lista del detalle de grabación (US5) y, indirectamente, el contador de
/// `ActiveCapture.marksPlaced` durante la captura.

final class LiveMarksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LiveMark>>, String> {
  LiveMarksFamily._()
    : super(
        retry: null,
        name: r'liveMarksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Marcas de una grabación, ordenadas por instante (FR-008). Alimenta la
  /// lista del detalle de grabación (US5) y, indirectamente, el contador de
  /// `ActiveCapture.marksPlaced` durante la captura.

  LiveMarksProvider call(String recordingId) =>
      LiveMarksProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'liveMarksProvider';
}
