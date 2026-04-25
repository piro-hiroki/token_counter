import 'dart:math';

import 'sp_proto_reader.dart';

/// Pure-Dart SentencePiece unigram-LM tokenizer.
///
/// Implements the Viterbi forward pass to find the maximum-likelihood
/// segmentation of the input text, then returns the token count.
///
/// Normalization applied before Viterbi:
/// - Leading whitespace trimmed.
/// - Each whitespace run replaced by a single ▁ (U+2581).
/// - ▁ prepended to the first word.
///
/// This matches the default `nmt_nfkc` normalization used by most public
/// SentencePiece models (Gemini, Llama 2, etc.). Models that apply additional
/// NFKC unicode normalization will be marginally less accurate because Dart's
/// `String` already uses NFC, but the difference in token count is typically
/// negligible.
class SpUnigramEncoder {
  SpUnigramEncoder(List<SpPiece> pieces) {
    for (final p in pieces) {
      if (p.type == 1 || p.type == 4) {
        // NORMAL or USER_DEFINED
        _vocab[p.piece] = p.score;
        if (p.piece.length > _maxLen) _maxLen = p.piece.length;
      } else if (p.type == 2) {
        // UNKNOWN — use its score as unk penalty
        _unkScore = p.score.isInfinite ? -100.0 : p.score;
      }
    }
  }

  final Map<String, double> _vocab = {};
  double _unkScore = -100.0;
  int _maxLen = 0;

  /// Returns the number of SentencePiece tokens [text] encodes to.
  int count(String text) {
    if (text.isEmpty) return 0;
    final normalized = _normalize(text);
    if (normalized.isEmpty) return 0;
    return _viterbiCount(normalized);
  }

  String _normalize(String text) {
    // Collapse whitespace runs → single ▁, prepend ▁ to first non-space char.
    final buf = StringBuffer('▁');
    var prevWasSpace = true;
    for (final ch in text.runes) {
      if (ch == 0x20 || ch == 0x09 || ch == 0x0A || ch == 0x0D ||
          ch == 0x3000) {
        if (!prevWasSpace) buf.write('▁');
        prevWasSpace = true;
      } else {
        buf.writeCharCode(ch);
        prevWasSpace = false;
      }
    }
    return buf.toString();
  }

  int _viterbiCount(String text) {
    // Work with UTF-16 code units for O(1) substring access. SentencePiece
    // vocab entries are also UTF-16 strings in Dart.
    final n = text.length;
    final bestScore = List.filled(n + 1, double.negativeInfinity);
    final bestCount = List.filled(n + 1, 0);
    bestScore[0] = 0.0;

    for (var i = 0; i < n; i++) {
      if (bestScore[i].isInfinite) continue;

      final maxEnd = min(n, i + _maxLen);
      for (var j = i + 1; j <= maxEnd; j++) {
        final piece = text.substring(i, j);
        final score = _vocab[piece];
        if (score != null) {
          final candidate = bestScore[i] + score;
          if (candidate > bestScore[j]) {
            bestScore[j] = candidate;
            bestCount[j] = bestCount[i] + 1;
          }
        }
      }

      // Byte-fallback: if position i+1 is still unreachable, consume one
      // UTF-16 code unit as an unknown token.
      if (bestScore[i + 1].isInfinite) {
        bestScore[i + 1] = bestScore[i] + _unkScore;
        bestCount[i + 1] = bestCount[i] + 1;
      }
    }

    return bestCount[n] > 0 ? bestCount[n] : 1;
  }
}
