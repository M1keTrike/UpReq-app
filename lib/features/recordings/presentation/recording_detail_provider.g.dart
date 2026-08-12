// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recordingDetail)
final recordingDetailProvider = RecordingDetailFamily._();

final class RecordingDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecordingDetailState>,
          RecordingDetailState,
          Stream<RecordingDetailState>
        >
    with
        $FutureModifier<RecordingDetailState>,
        $StreamProvider<RecordingDetailState> {
  RecordingDetailProvider._({
    required RecordingDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'recordingDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordingDetailHash();

  @override
  String toString() {
    return r'recordingDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<RecordingDetailState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RecordingDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return recordingDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordingDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordingDetailHash() => r'88f9038fb20a05091a9296780d5d92c0aab8efc0';

final class RecordingDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<RecordingDetailState>, String> {
  RecordingDetailFamily._()
    : super(
        retry: null,
        name: r'recordingDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecordingDetailProvider call(String recordingId) =>
      RecordingDetailProvider._(argument: recordingId, from: this);

  @override
  String toString() => r'recordingDetailProvider';
}
