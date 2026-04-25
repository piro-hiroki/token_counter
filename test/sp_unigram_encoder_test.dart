import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:token_counter/token_counter.dart';
import 'package:token_counter/src/sentencepiece/sp_proto_reader.dart';
import 'package:token_counter/src/sentencepiece/sp_unigram_encoder.dart';

// ---------------------------------------------------------------------------
// Minimal synthetic SentencePiece .model builder
// ---------------------------------------------------------------------------
//
// Protobuf layout we emit:
//   message ModelProto {
//     repeated SentencePiece pieces = 1;  // field 1, wire 2
//   }
//   message SentencePiece {
//     string piece = 1;   // field 1, wire 2
//     float  score = 2;   // field 2, wire 5
//     uint32 type  = 3;   // field 3, wire 0  (1=NORMAL, 2=UNKNOWN)
//   }

List<int> _varint(int value) {
  final out = <int>[];
  while (value > 0x7F) {
    out.add((value & 0x7F) | 0x80);
    value >>= 7;
  }
  out.add(value);
  return out;
}

List<int> _float32Bytes(double v) {
  final bd = ByteData(4);
  bd.setFloat32(0, v, Endian.little);
  return bd.buffer.asUint8List().toList();
}

List<int> _encodePiece(String piece, double score, int type) {
  final pieceBytes = utf8.encode(piece);
  final buf = <int>[];
  // field 1 (piece), wire 2
  buf.addAll(_varint((1 << 3) | 2));
  buf.addAll(_varint(pieceBytes.length));
  buf.addAll(pieceBytes);
  // field 2 (score), wire 5 (float32)
  buf.addAll(_varint((2 << 3) | 5));
  buf.addAll(_float32Bytes(score));
  // field 3 (type), wire 0
  buf.addAll(_varint((3 << 3) | 0));
  buf.addAll(_varint(type));
  return buf;
}

Uint8List _buildSpModel(List<(String, double, int)> entries) {
  final out = <int>[];
  for (final e in entries) {
    final pieceMsg = _encodePiece(e.$1, e.$2, e.$3);
    // field 1 (pieces), wire 2
    out.addAll(_varint((1 << 3) | 2));
    out.addAll(_varint(pieceMsg.length));
    out.addAll(pieceMsg);
  }
  return Uint8List.fromList(out);
}

// Synthetic vocab:
//   <unk>  score=-100  type=2 (UNKNOWN)
//   ▁Hello score=-1    type=1 (NORMAL)
//   ▁World score=-2    type=1
//   ▁H     score=-3    type=1
//   ello   score=-4    type=1
//   ▁W     score=-5    type=1
//   orld   score=-6    type=1
//   individual chars a-z, A-Z → score=-10
final _syntheticModel = _buildSpModel([
  ('<unk>', -100.0, 2),
  ('▁Hello', -1.0, 1),
  ('▁World', -2.0, 1),
  ('▁H', -3.0, 1),
  ('ello', -4.0, 1),
  ('▁W', -5.0, 1),
  ('orld', -6.0, 1),
  for (var i = 0; i < 26; i++) ...[
    (String.fromCharCode(0x61 + i), -10.0, 1), // a-z
    (String.fromCharCode(0x41 + i), -10.0, 1), // A-Z
  ],
]);

Future<TokenCounter> _exactCounter(LlmModel model) =>
    TokenCounter.forModel(model)
        .loadSpVocab(BytesSpVocabLoader(_syntheticModel));

// ---------------------------------------------------------------------------

void main() {
  group('SpProtoReader', () {
    test('parses piece, score, type from synthetic model', () {
      final pieces = SpProtoReader.readPieces(_syntheticModel);
      expect(pieces.isNotEmpty, isTrue);

      final unk = pieces.firstWhere((p) => p.type == 2);
      expect(unk.piece, '<unk>');

      final hello = pieces.firstWhere((p) => p.piece == '▁Hello');
      expect(hello.type, 1);
      expect(hello.score, closeTo(-1.0, 0.001));
    });
  });

  group('SpUnigramEncoder', () {
    late SpUnigramEncoder encoder;

    setUpAll(() {
      final pieces = SpProtoReader.readPieces(_syntheticModel);
      encoder = SpUnigramEncoder(pieces);
    });

    test('empty string → 0', () => expect(encoder.count(''), 0));

    test('"Hello" segments to 1 token (▁Hello)', () {
      // Normalized: ▁Hello → matches vocab entry ▁Hello directly → 1 token.
      expect(encoder.count('Hello'), 1);
    });

    test('"Hello World" segments to 2 tokens', () {
      // ▁Hello ▁World → 2 tokens.
      expect(encoder.count('Hello World'), 2);
    });

    test('deterministic', () {
      final a = encoder.count('Hello World');
      final b = encoder.count('Hello World');
      expect(a, b);
    });
  });

  group('TokenCounter.loadSpVocab', () {
    test('isExact is true after loadSpVocab', () async {
      final c = await _exactCounter(LlmModel.gemini2Pro);
      expect(c.isExact, isTrue);
    });

    test('throws for tiktoken families', () {
      expect(
        () => TokenCounter.forModel(LlmModel.gpt4o)
            .loadSpVocab(BytesSpVocabLoader(_syntheticModel)),
        throwsArgumentError,
      );
    });

    test('countMessages uses SP encoder', () async {
      final c = await _exactCounter(LlmModel.gemini2Pro);
      final n = c.countMessages([const ChatMessage.user('Hello')]);
      expect(n, greaterThan(1));
    });
  });
}
