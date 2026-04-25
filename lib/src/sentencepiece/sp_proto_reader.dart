import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// A single vocabulary entry from a SentencePiece `.model` file.
class SpPiece {
  const SpPiece({required this.piece, required this.score, required this.type});

  /// The token surface form (may contain ▁ for spaces).
  final String piece;

  /// Log-probability used for Viterbi decoding.
  final double score;

  /// Token type (1=NORMAL, 2=UNKNOWN, 3=CONTROL, 4=USER_DEFINED, 6=BYTE).
  final int type;
}

/// Minimal protobuf reader that extracts vocabulary entries from a
/// SentencePiece `.model` file without a generated proto runtime.
///
/// Only the fields needed for tokenization are decoded:
/// - `ModelProto.pieces` (field 1) — repeated `SentencePiece` messages
///   - `SentencePiece.piece` (field 1) — string
///   - `SentencePiece.score` (field 2) — float32
///   - `SentencePiece.type` (field 3) — uint32
///
/// All other fields are skipped according to the protobuf wire format.
class SpProtoReader {
  const SpProtoReader._();

  /// Parses [data] (raw bytes of a `.model` file) and returns all vocabulary
  /// entries in order.
  static List<SpPiece> readPieces(Uint8List data) {
    final pieces = <SpPiece>[];
    var pos = 0;
    while (pos < data.length) {
      final tag = _varint(data, pos);
      pos = tag.$2;
      final fieldNumber = tag.$1 >> 3;
      final wireType = tag.$1 & 0x7;

      if (fieldNumber == 1 && wireType == 2) {
        final len = _varint(data, pos);
        pos = len.$2;
        final end = pos + len.$1;
        pieces.add(_readPiece(data, pos, end));
        pos = end;
      } else {
        pos = _skipField(data, pos, wireType);
        if (pos < 0) break; // Malformed data — stop parsing.
      }
    }
    return pieces;
  }

  static SpPiece _readPiece(Uint8List data, int start, int end) {
    String piece = '';
    double score = 0.0;
    int type = 1;
    var pos = start;

    while (pos < end) {
      final tag = _varint(data, pos);
      pos = tag.$2;
      final fieldNumber = tag.$1 >> 3;
      final wireType = tag.$1 & 0x7;

      if (fieldNumber == 1 && wireType == 2) {
        final len = _varint(data, pos);
        pos = len.$2;
        piece = utf8.decode(data.sublist(pos, pos + len.$1),
            allowMalformed: true);
        pos += len.$1;
      } else if (fieldNumber == 2 && wireType == 5) {
        score = ByteData.sublistView(data, pos, pos + 4)
            .getFloat32(0, Endian.little)
            .toDouble();
        pos += 4;
      } else if (fieldNumber == 3 && wireType == 0) {
        final v = _varint(data, pos);
        type = v.$1;
        pos = v.$2;
      } else {
        pos = _skipField(data, pos, wireType);
        if (pos < 0) break;
      }
    }

    return SpPiece(piece: piece, score: score, type: type);
  }

  /// Decodes a varint starting at [pos] and returns (value, nextPos).
  static (int, int) _varint(Uint8List data, int pos) {
    var result = 0;
    var shift = 0;
    while (pos < data.length) {
      final byte = data[pos++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) return (result, pos);
      shift += 7;
      if (shift >= 64) break; // Overflow guard.
    }
    return (result, pos);
  }

  /// Skips one field value of the given [wireType] and returns the new pos.
  /// Returns -1 on unrecognized wire type.
  static int _skipField(Uint8List data, int pos, int wireType) {
    switch (wireType) {
      case 0: // Varint
        while (pos < data.length && (data[pos++] & 0x80) != 0) {}
        return pos;
      case 1: // 64-bit
        return pos + 8;
      case 2: // Length-delimited
        final len = _varint(data, pos);
        return len.$2 + len.$1;
      case 5: // 32-bit
        return pos + 4;
      default:
        return -1;
    }
  }
}

// dart:math min is used internally by SpUnigramEncoder.
final _kMin = min; // ignore: unused_element
