/// Broad Unicode script / category buckets used by the heuristic tokenizer.
enum ScriptBucket {
  /// ASCII letters (a-z, A-Z).
  latin,

  /// Latin-script letters outside ASCII (e.g., accented European letters).
  latinExtended,

  /// ASCII digits (0-9) and other decimal digits.
  digit,

  /// ASCII or Unicode whitespace.
  whitespace,

  /// CJK Unified Ideographs (Chinese characters / Kanji).
  cjkIdeograph,

  /// Japanese Hiragana.
  hiragana,

  /// Japanese Katakana (incl. half-width).
  katakana,

  /// Korean Hangul syllables and Jamo.
  hangul,

  /// Arabic script.
  arabic,

  /// Cyrillic script.
  cyrillic,

  /// Devanagari (Hindi etc.).
  devanagari,

  /// Thai script.
  thai,

  /// Emoji and pictographic symbols.
  emoji,

  /// Punctuation and other symbols.
  symbol,

  /// Anything not otherwise classified.
  other,
}

/// Classifies a single Unicode code point into a [ScriptBucket].
ScriptBucket classifyCodeUnit(int cp) {
  // Fast ASCII path.
  if (cp < 0x80) {
    if (cp >= 0x30 && cp <= 0x39) return ScriptBucket.digit;
    if ((cp >= 0x41 && cp <= 0x5A) || (cp >= 0x61 && cp <= 0x7A)) {
      return ScriptBucket.latin;
    }
    if (cp == 0x20 || cp == 0x09 || cp == 0x0A || cp == 0x0D) {
      return ScriptBucket.whitespace;
    }
    return ScriptBucket.symbol;
  }

  // Latin-1 Supplement + Latin Extended-A/B + IPA Extensions.
  if (cp >= 0x00A0 && cp <= 0x024F) {
    if (cp == 0x00A0) return ScriptBucket.whitespace;
    return ScriptBucket.latinExtended;
  }

  // Cyrillic.
  if (cp >= 0x0400 && cp <= 0x04FF) return ScriptBucket.cyrillic;

  // Arabic.
  if (cp >= 0x0600 && cp <= 0x06FF) return ScriptBucket.arabic;

  // Devanagari.
  if (cp >= 0x0900 && cp <= 0x097F) return ScriptBucket.devanagari;

  // Thai.
  if (cp >= 0x0E00 && cp <= 0x0E7F) return ScriptBucket.thai;

  // Hangul Jamo + Syllables + Compatibility Jamo.
  if ((cp >= 0x1100 && cp <= 0x11FF) ||
      (cp >= 0x3130 && cp <= 0x318F) ||
      (cp >= 0xAC00 && cp <= 0xD7AF)) {
    return ScriptBucket.hangul;
  }

  // Hiragana.
  if (cp >= 0x3040 && cp <= 0x309F) return ScriptBucket.hiragana;

  // Katakana (full-width + phonetic extensions).
  if ((cp >= 0x30A0 && cp <= 0x30FF) || (cp >= 0x31F0 && cp <= 0x31FF)) {
    return ScriptBucket.katakana;
  }

  // Half-width Katakana.
  if (cp >= 0xFF65 && cp <= 0xFF9F) return ScriptBucket.katakana;

  // CJK Unified Ideographs + Extensions A/B + Compatibility Ideographs.
  if ((cp >= 0x3400 && cp <= 0x4DBF) ||
      (cp >= 0x4E00 && cp <= 0x9FFF) ||
      (cp >= 0xF900 && cp <= 0xFAFF) ||
      (cp >= 0x20000 && cp <= 0x2A6DF) ||
      (cp >= 0x2A700 && cp <= 0x2EBEF)) {
    return ScriptBucket.cjkIdeograph;
  }

  // Ideographic whitespace / CJK symbols that effectively act as separators.
  if (cp == 0x3000) return ScriptBucket.whitespace;

  // Emoji ranges (simplified — covers the common Supplemental Symbols and
  // Pictographs blocks; not exhaustive).
  if ((cp >= 0x1F300 && cp <= 0x1FAFF) ||
      (cp >= 0x2600 && cp <= 0x27BF) ||
      (cp >= 0x1F900 && cp <= 0x1F9FF)) {
    return ScriptBucket.emoji;
  }

  // CJK symbols and punctuation.
  if (cp >= 0x3000 && cp <= 0x303F) return ScriptBucket.symbol;

  // Full-width ASCII / punctuation.
  if (cp >= 0xFF00 && cp <= 0xFFEF) {
    if (cp >= 0xFF10 && cp <= 0xFF19) return ScriptBucket.digit;
    if ((cp >= 0xFF21 && cp <= 0xFF3A) || (cp >= 0xFF41 && cp <= 0xFF5A)) {
      return ScriptBucket.latin;
    }
    return ScriptBucket.symbol;
  }

  // General punctuation and misc symbols.
  if (cp >= 0x2000 && cp <= 0x206F) return ScriptBucket.symbol;
  if (cp >= 0x2100 && cp <= 0x214F) return ScriptBucket.symbol;
  if (cp >= 0x2190 && cp <= 0x2BFF) return ScriptBucket.symbol;

  return ScriptBucket.other;
}
