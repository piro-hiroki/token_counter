import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:token_counter/token_counter.dart';
import 'package:token_counter/src/tiktoken/tiktoken_bpe_encoder.dart';
import 'package:token_counter/src/tiktoken/tiktoken_patterns.dart';
import 'package:token_counter/src/tiktoken/tiktoken_vocab_parser.dart';

// Builds a minimal synthetic .tiktoken file for deterministic testing.
// Each entry: base64(bytes) + space + rank.
Uint8List _buildVocab(Map<List<int>, int> entries) {
  final lines = entries.entries.map((e) {
    final b64 = base64.encode(e.key);
    return '$b64 ${e.value}';
  }).join('\n');
  return Uint8List.fromList(utf8.encode(lines));
}

// Synthetic vocab that allows deterministic BPE tests:
//   - All 256 single bytes are present (rank = byte value, 0-255).
//   - A few 2- and 3-byte merges:
//       "ab" → 256,  "abc" → 257,  "He" → 300,  "ll" → 301,  "Hello" → 302
final _syntheticVocabBytes = () {
  final entries = <List<int>, int>{};
  for (var b = 0; b < 256; b++) {
    entries[[b]] = b;
  }
  entries[utf8.encode('ab')] = 256;
  entries[utf8.encode('abc')] = 257;
  entries[utf8.encode('He')] = 300;
  entries[utf8.encode('ll')] = 301;
  // "Hello" requires pieces "Hell" + "o" → but "Hell" = He+ll = 302
  entries[utf8.encode('Hell')] = 302;
  entries[utf8.encode('Hello')] = 303;
  return _buildVocab(entries);
}();

Future<TokenCounter> _exactCounter(LlmModel model) async {
  return TokenCounter.forModel(model).loadVocab(
    BytesVocabLoader(_syntheticVocabBytes),
  );
}

void main() {
  group('TiktokenVocabParser', () {
    test('parses the synthetic vocab correctly', () {
      final vocab = TiktokenVocabParser.parse(_syntheticVocabBytes);
      expect(vocab[String.fromCharCode(65)], 65); // 'A' → 65
      expect(vocab['ab'], 256);
      expect(vocab['abc'], 257);
    });
  });

  group('TiktokenBpeEncoder.count', () {
    late Map<String, int> vocab;

    setUpAll(() {
      vocab = TiktokenVocabParser.parse(_syntheticVocabBytes);
    });

    test('empty string → 0', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      expect(encoder.count(''), 0);
    });

    test('single ASCII letter → 1', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      // "a" is a single byte → rank 97 → 1 token
      expect(encoder.count('a'), 1);
    });

    test('"ab" merges to 1 token', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      expect(encoder.count('ab'), 1);
    });

    test('"ba" stays at 2 tokens (no merge for "ba")', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      expect(encoder.count('ba'), 2);
    });

    test('"abc" merges to 1 token (via ab→256, then abc→257)', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      // "ab" merges first (rank 256 < 257), then "abc" merges.
      expect(encoder.count('abc'), 1);
    });

    test('"Hello" merges to 1 token', () {
      final encoder = TiktokenBpeEncoder(
        vocab: vocab,
        pattern: TiktokenPatterns.forFamily(TokenizerFamily.cl100kBase),
      );
      // He(300) + ll(301) → Hell(302) → Hello(303)
      expect(encoder.count('Hello'), 1);
    });
  });

  group('TokenCounter.loadVocab', () {
    test('isExact is false before loadVocab', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      expect(counter.isExact, isFalse);
    });

    test('isExact is true after loadVocab', () async {
      final counter = await _exactCounter(LlmModel.gpt4o);
      expect(counter.isExact, isTrue);
    });

    test('exact counter produces deterministic results', () async {
      final counter = await _exactCounter(LlmModel.gpt4o);
      expect(counter.count('Hello'), counter.count('Hello'));
    });

    test('loadVocab throws for non-tiktoken families', () async {
      expect(
        () => TokenCounter.forModel(LlmModel.claude4Sonnet).loadVocab(
          BytesVocabLoader(_syntheticVocabBytes),
        ),
        throwsArgumentError,
      );
    });

    test('special tokens each count as 1 token', () async {
      final counter = await TokenCounter.forModel(LlmModel.gpt4o).loadVocab(
        BytesVocabLoader(_syntheticVocabBytes),
        specialTokens: const {'<|end|>': 9999},
      );
      // "<|end|>" should be 1 token, "ab" should be 1 token → total 2
      expect(counter.count('ab<|end|>'), 2);
    });

    test('countMessages uses exact encoder when loaded', () async {
      final counter = await _exactCounter(LlmModel.gpt4o);
      final n = counter.countMessages([const ChatMessage.user('ab')]);
      // "ab" = 1 token + overhead = 1 + 4 (per-msg) + 2 (priming) = 7
      expect(n, greaterThan(1));
    });
  });
}
