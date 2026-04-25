import 'llm_model.dart';
import 'script_classifier.dart';

/// Heuristic token-count estimator.
///
/// The estimator walks each Unicode code point, classifies it into a
/// [ScriptBucket], and multiplies character counts by family-specific
/// coefficients derived from published tokenizer benchmarks.
///
/// This is an approximation — expect ±10-20% error versus the exact
/// tokenizer. Load real vocabularies when you need tighter bounds.
class HeuristicTokenizer {
  /// Creates a heuristic tokenizer for [family].
  const HeuristicTokenizer(this.family);

  /// The tokenizer family whose coefficients are used.
  final TokenizerFamily family;

  /// Estimates the number of tokens in [text] for this tokenizer family.
  int count(String text) {
    if (text.isEmpty) return 0;

    final counts = _countBuckets(text);
    final coeffs = _coefficients[family]!;

    double tokens = 0;
    counts.forEach((bucket, n) {
      tokens += n * (coeffs[bucket] ?? coeffs[ScriptBucket.other]!);
    });

    // Latin text benefits heavily from BPE merges on frequent words. The
    // per-character coefficient already accounts for most of that, but very
    // short inputs undershoot. Enforce a minimum of 1 token for any non-empty
    // input.
    final rounded = tokens.ceil();
    return rounded < 1 ? 1 : rounded;
  }

  Map<ScriptBucket, int> _countBuckets(String text) {
    final counts = <ScriptBucket, int>{};
    for (final cp in text.runes) {
      final bucket = classifyCodeUnit(cp);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  /// Tokens-per-character coefficients per script bucket, per family.
  ///
  /// Values are drawn from community measurements on representative corpora:
  /// English ~4 chars/token, Japanese ~1-2 chars/token depending on vocab,
  /// Chinese ~1 char/token, Korean ~1 char/token.
  static const Map<TokenizerFamily, Map<ScriptBucket, double>> _coefficients = {
    TokenizerFamily.o200kBase: {
      ScriptBucket.latin: 0.25,
      ScriptBucket.latinExtended: 0.40,
      ScriptBucket.digit: 0.30,
      ScriptBucket.whitespace: 0.10,
      ScriptBucket.cjkIdeograph: 0.90,
      ScriptBucket.hiragana: 0.50,
      ScriptBucket.katakana: 0.60,
      ScriptBucket.hangul: 0.80,
      ScriptBucket.arabic: 0.55,
      ScriptBucket.cyrillic: 0.55,
      ScriptBucket.devanagari: 0.70,
      ScriptBucket.thai: 0.75,
      ScriptBucket.emoji: 2.00,
      ScriptBucket.symbol: 0.35,
      ScriptBucket.other: 0.50,
    },
    TokenizerFamily.cl100kBase: {
      ScriptBucket.latin: 0.27,
      ScriptBucket.latinExtended: 0.55,
      ScriptBucket.digit: 0.35,
      ScriptBucket.whitespace: 0.15,
      ScriptBucket.cjkIdeograph: 1.40,
      ScriptBucket.hiragana: 0.85,
      ScriptBucket.katakana: 1.00,
      ScriptBucket.hangul: 1.20,
      ScriptBucket.arabic: 0.85,
      ScriptBucket.cyrillic: 0.90,
      ScriptBucket.devanagari: 1.10,
      ScriptBucket.thai: 1.20,
      ScriptBucket.emoji: 2.50,
      ScriptBucket.symbol: 0.40,
      ScriptBucket.other: 0.70,
    },
    TokenizerFamily.claude: {
      ScriptBucket.latin: 0.28,
      ScriptBucket.latinExtended: 0.50,
      ScriptBucket.digit: 0.35,
      ScriptBucket.whitespace: 0.12,
      ScriptBucket.cjkIdeograph: 1.10,
      ScriptBucket.hiragana: 0.70,
      ScriptBucket.katakana: 0.85,
      ScriptBucket.hangul: 1.00,
      ScriptBucket.arabic: 0.70,
      ScriptBucket.cyrillic: 0.75,
      ScriptBucket.devanagari: 0.95,
      ScriptBucket.thai: 1.00,
      ScriptBucket.emoji: 2.20,
      ScriptBucket.symbol: 0.40,
      ScriptBucket.other: 0.65,
    },
    TokenizerFamily.gemini: {
      ScriptBucket.latin: 0.26,
      ScriptBucket.latinExtended: 0.45,
      ScriptBucket.digit: 0.30,
      ScriptBucket.whitespace: 0.10,
      ScriptBucket.cjkIdeograph: 1.00,
      ScriptBucket.hiragana: 0.60,
      ScriptBucket.katakana: 0.75,
      ScriptBucket.hangul: 0.90,
      ScriptBucket.arabic: 0.65,
      ScriptBucket.cyrillic: 0.65,
      ScriptBucket.devanagari: 0.85,
      ScriptBucket.thai: 0.85,
      ScriptBucket.emoji: 2.00,
      ScriptBucket.symbol: 0.35,
      ScriptBucket.other: 0.55,
    },
    TokenizerFamily.llama: {
      ScriptBucket.latin: 0.26,
      ScriptBucket.latinExtended: 0.45,
      ScriptBucket.digit: 0.35,
      ScriptBucket.whitespace: 0.12,
      ScriptBucket.cjkIdeograph: 1.20,
      ScriptBucket.hiragana: 0.75,
      ScriptBucket.katakana: 0.90,
      ScriptBucket.hangul: 1.05,
      ScriptBucket.arabic: 0.75,
      ScriptBucket.cyrillic: 0.70,
      ScriptBucket.devanagari: 1.00,
      ScriptBucket.thai: 1.10,
      ScriptBucket.emoji: 2.30,
      ScriptBucket.symbol: 0.40,
      ScriptBucket.other: 0.65,
    },
  };
}
