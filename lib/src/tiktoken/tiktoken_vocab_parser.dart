import 'dart:convert';
import 'dart:typed_data';

/// Parses the `.tiktoken` vocabulary file format into a rank map.
///
/// The `.tiktoken` format has one entry per line:
/// ```
/// {base64(token_bytes)} {rank}
/// ```
///
/// Internally the map keys are the token bytes represented as a Dart
/// [String] via [String.fromCharCodes]. This lets us use Dart's native
/// string equality and hashing for O(1) lookups during BPE encoding,
/// while keeping the keys immutable and internable.
class TiktokenVocabParser {
  const TiktokenVocabParser._();

  /// Parses [bytes] (the raw contents of a `.tiktoken` file) and returns
  /// a map from token (as Latin-1 string) to its BPE rank.
  static Map<String, int> parse(Uint8List bytes) {
    final content = utf8.decode(bytes);
    final vocab = <String, int>{};

    for (final line in content.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) continue;

      final spaceIdx = trimmed.lastIndexOf(' ');
      if (spaceIdx < 0) continue;

      final tokenBytes = base64.decode(trimmed.substring(0, spaceIdx));
      final rank = int.parse(trimmed.substring(spaceIdx + 1));
      vocab[String.fromCharCodes(tokenBytes)] = rank;
    }

    return vocab;
  }
}
