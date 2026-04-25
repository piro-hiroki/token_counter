import '../llm_model.dart';

/// Pre-tokenization regex patterns for tiktoken families.
///
/// These split raw text into pieces before BPE encoding runs on the
/// UTF-8 bytes of each piece independently — mirroring what the
/// reference tiktoken implementation does.
class TiktokenPatterns {
  /// Returns the pre-tokenization [RegExp] for [family].
  ///
  /// Falls back to the `cl100k_base` pattern for families that are not
  /// tiktoken-based (they should use heuristic mode instead).
  static RegExp forFamily(TokenizerFamily family) {
    switch (family) {
      case TokenizerFamily.o200kBase:
        return _o200k;
      case TokenizerFamily.cl100kBase:
      default:
        return _cl100k;
    }
  }

  // cl100k_base (GPT-4, GPT-3.5-turbo)
  // Reference pattern (with (?i:) expanded manually because Dart's RegExp
  // does not support inline mode flags):
  //   (?i:'s|'t|'re|'ve|'m|'ll|'d)
  //   |[^\r\n\p{L}\p{N}]?\p{L}+
  //   |\p{N}{1,3}
  //   | ?[^\s\p{L}\p{N}]+[\r\n]*
  //   |\s*[\r\n]+
  //   |\s+(?!\S)
  //   |\s+
  static final _cl100k = RegExp(
    r"(?:'[Ss]|'[Tt]|'[Rr][Ee]|'[Vv][Ee]|'[Mm]|'[Ll][Ll]|'[Dd])"
    r"|[^\r\n\p{L}\p{N}]?\p{L}+"
    r"|\p{N}{1,3}"
    r"| ?[^\s\p{L}\p{N}]+[\r\n]*"
    r"|\s*[\r\n]+"
    r"|\s+(?!\S)"
    r"|\s+",
    unicode: true,
  );

  // o200k_base (GPT-4o, GPT-4.1, o-series)
  // Contraction alternatives appear last (different ordering than cl100k).
  static final _o200k = RegExp(
    r"[^\r\n\p{L}\p{N}]?\p{L}+"
    r"|\p{N}{1,3}"
    r"| ?[^\s\p{L}\p{N}]+[\r\n]*"
    r"|\s*[\r\n]+"
    r"|\s+(?!\S)"
    r"|\s+"
    r"|(?:'[Ss]|'[Tt]|'[Rr][Ee]|'[Vv][Ee]|'[Mm]|'[Ll][Ll]|'[Dd])",
    unicode: true,
  );
}

/// Well-known special-token sets that can be passed to [TiktokenBpeEncoder].
///
/// Special tokens are NOT in the regular `.tiktoken` vocabulary file; they
/// must be supplied separately. Each entry is token-string → rank.
class TiktokenSpecialTokens {
  const TiktokenSpecialTokens._();

  /// Special tokens for the `cl100k_base` vocabulary (GPT-4, GPT-3.5-turbo).
  static const Map<String, int> cl100kBase = {
    '<|endoftext|>': 100257,
    '<|fim_prefix|>': 100258,
    '<|fim_middle|>': 100259,
    '<|fim_suffix|>': 100260,
    '<|endofprompt|>': 100276,
  };

  /// Special tokens for the `o200k_base` vocabulary (GPT-4o, o-series).
  static const Map<String, int> o200kBase = {
    '<|endoftext|>': 199999,
    '<|endofprompt|>': 200018,
  };
}

