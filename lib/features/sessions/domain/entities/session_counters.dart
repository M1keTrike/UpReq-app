/// Contadores del guion de una sesión (FR-013): puntos vivos agrupados por
/// estado. `total` es la suma de los tres, nunca contada aparte.
final class SessionCounters {
  const SessionCounters({
    required this.pending,
    required this.covered,
    required this.skipped,
  });

  final int pending;
  final int covered;
  final int skipped;

  int get total => pending + covered + skipped;

  @override
  bool operator ==(Object other) =>
      other is SessionCounters &&
      other.pending == pending &&
      other.covered == covered &&
      other.skipped == skipped;

  @override
  int get hashCode => Object.hash(pending, covered, skipped);

  @override
  String toString() => 'SessionCounters(pending: $pending, covered: $covered, skipped: $skipped)';
}
