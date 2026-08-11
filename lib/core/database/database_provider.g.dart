// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive: true` a propósito: la conexión SQLite debe sobrevivir a la
/// navegación entre pantallas. Si el provider se destruyera al salir de una
/// ruta (comportamiento por defecto de Riverpod), cada vuelta a una pantalla
/// reabriría la base de datos, perdiendo la ventaja de mantener una única
/// conexión y arriesgando fugas de recursos nativos de SQLite.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// `keepAlive: true` a propósito: la conexión SQLite debe sobrevivir a la
/// navegación entre pantallas. Si el provider se destruyera al salir de una
/// ruta (comportamiento por defecto de Riverpod), cada vuelta a una pantalla
/// reabriría la base de datos, perdiendo la ventaja de mantener una única
/// conexión y arriesgando fugas de recursos nativos de SQLite.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// `keepAlive: true` a propósito: la conexión SQLite debe sobrevivir a la
  /// navegación entre pantallas. Si el provider se destruyera al salir de una
  /// ruta (comportamiento por defecto de Riverpod), cada vuelta a una pantalla
  /// reabriría la base de datos, perdiendo la ventaja de mantener una única
  /// conexión y arriesgando fugas de recursos nativos de SQLite.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'97c8cc8f253e7c6ea3b170950a83a1ed62dac332';
