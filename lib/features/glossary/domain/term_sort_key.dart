/// Función pura de normalización de `term_sort_key` (data-model.md, entidad
/// `GlossaryTerm`): minúsculas y sin acentos, para que el orden alfabético de
/// la lista ignore mayúsculas y diacríticos. No importa `package:flutter`.
library;

const Map<String, String> _diacritics = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
};

/// Calcula el `term_sort_key` de un término: lo pasa a minúsculas y sustituye
/// cada letra acentuada por su equivalente sin diacrítico. Se recalcula en
/// cada escritura (creación y edición) del término.
String computeTermSortKey(String term) {
  final lower = term.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}
