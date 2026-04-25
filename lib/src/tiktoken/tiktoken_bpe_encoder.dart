import 'dart:convert';

/// Exact tiktoken-compatible BPE token counter.
///
/// Algorithm:
/// 1. Pre-tokenize the input text using the family-specific [pattern].
/// 2. UTF-8 encode each piece.
/// 3. Run BPE on the byte sequence: repeatedly merge the adjacent pair with
///    the lowest rank in [vocab] until no more merges are possible.
/// 4. Count the resulting tokens.
///
/// Special tokens (e.g. `<|endoftext|>`) are matched verbatim before the
/// regex pre-tokenization step and each counted as exactly 1 token.
class TiktokenBpeEncoder {
  TiktokenBpeEncoder({
    required this.vocab,
    required this.pattern,
    this.specialTokens = const {},
  });

  /// BPE vocabulary: token bytes (as Latin-1 string) → BPE rank.
  final Map<String, int> vocab;

  /// Pre-tokenization pattern for this vocab family.
  final RegExp pattern;

  /// Optional special tokens: token string → rank. Each occurrence in the
  /// input is counted as exactly 1 token and removed before regex splitting.
  final Map<String, int> specialTokens;

  /// Returns the exact number of tokens [text] encodes to.
  int count(String text) {
    if (text.isEmpty) return 0;
    if (specialTokens.isEmpty) return _countRegularText(text);

    // Build a regex that matches any special token verbatim.
    final escapedKeys = specialTokens.keys.map(RegExp.escape).join('|');
    final specialPattern = RegExp(escapedKeys);

    var total = 0;
    var pos = 0;
    for (final match in specialPattern.allMatches(text)) {
      if (match.start > pos) {
        total += _countRegularText(text.substring(pos, match.start));
      }
      total += 1; // Each special token = exactly 1 token.
      pos = match.end;
    }
    if (pos < text.length) {
      total += _countRegularText(text.substring(pos));
    }
    return total;
  }

  int _countRegularText(String text) {
    if (text.isEmpty) return 0;
    var total = 0;
    for (final match in pattern.allMatches(text)) {
      final piece = match.group(0)!;
      if (piece.isEmpty) continue;
      total += _encodePieceCount(utf8.encode(piece));
    }
    return total;
  }

  /// Returns the number of BPE tokens the byte sequence encodes to.
  int _encodePieceCount(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    if (bytes.length == 1) return 1; // Single byte always present in vocab.

    // Represent each byte as a single-character Latin-1 string so we can use
    // Dart's native string == and hashCode for O(1) vocab lookups, and use
    // string concatenation for O(1) merges.
    final parts = [for (final b in bytes) String.fromCharCode(b)];

    while (parts.length > 1) {
      int? bestRank;
      int? bestIdx;

      for (var i = 0; i < parts.length - 1; i++) {
        final rank = vocab[parts[i] + parts[i + 1]];
        if (rank != null && (bestRank == null || rank < bestRank)) {
          bestRank = rank;
          bestIdx = i;
        }
      }

      if (bestIdx == null) break; // No more merges available.

      parts[bestIdx] = parts[bestIdx] + parts[bestIdx + 1];
      parts.removeAt(bestIdx + 1);
    }

    return parts.length;
  }
}
