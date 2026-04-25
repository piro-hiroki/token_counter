import 'dart:typed_data';

/// Abstract source from which raw `.tiktoken` vocabulary bytes are loaded.
///
/// Implement this interface to supply vocabulary data from any source —
/// Flutter assets, local files, in-memory bytes, or a custom network loader.
///
/// Example — loading from a Flutter asset (add the file to `pubspec.yaml`
/// under `flutter.assets` first):
///
/// ```dart
/// import 'package:flutter/services.dart';
///
/// class AssetVocabLoader extends TiktokenVocabLoader {
///   const AssetVocabLoader(this.assetPath);
///   final String assetPath;
///
///   @override
///   Future<Uint8List> load() async {
///     final data = await rootBundle.load(assetPath);
///     return data.buffer.asUint8List();
///   }
/// }
/// ```
///
/// Then:
/// ```dart
/// final counter = await TokenCounter.forModel(LlmModel.gpt4o)
///     .loadVocab(AssetVocabLoader('assets/o200k_base.tiktoken'));
/// ```
abstract class TiktokenVocabLoader {
  const TiktokenVocabLoader();

  /// Returns the raw bytes of the `.tiktoken` vocabulary file.
  Future<Uint8List> load();
}

/// Loads vocabulary from bytes already held in memory.
///
/// Useful when the caller has already downloaded or read the vocabulary file
/// and just needs to hand the bytes to the encoder.
///
/// ```dart
/// final bytes = File('cl100k_base.tiktoken').readAsBytesSync();
/// final counter = await TokenCounter.forModel(LlmModel.gpt4)
///     .loadVocab(BytesVocabLoader(bytes));
/// ```
class BytesVocabLoader extends TiktokenVocabLoader {
  const BytesVocabLoader(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> load() async => bytes;
}
