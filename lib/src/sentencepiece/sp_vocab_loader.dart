import 'dart:typed_data';

/// Abstract source from which raw SentencePiece `.model` file bytes are loaded.
///
/// Implement this interface to supply model data from any source — Flutter
/// assets, local files, or in-memory bytes.
///
/// Example — loading from a Flutter asset:
///
/// ```dart
/// import 'package:flutter/services.dart';
///
/// class AssetSpVocabLoader extends SpVocabLoader {
///   const AssetSpVocabLoader(this.assetPath);
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
/// final counter = await TokenCounter.forModel(LlmModel.gemini2Pro)
///     .loadSpVocab(AssetSpVocabLoader('assets/gemini.model'));
/// ```
///
/// SentencePiece `.model` files for open-source models (e.g. Llama 2) are
/// typically distributed alongside the model weights. Google and Anthropic
/// models use proprietary vocabulary files that are not publicly available;
/// for those providers the heuristic estimator is used by default.
abstract class SpVocabLoader {
  const SpVocabLoader();

  /// Returns the raw bytes of the SentencePiece `.model` file.
  Future<Uint8List> load();
}

/// Loads a SentencePiece vocabulary from bytes already held in memory.
///
/// ```dart
/// final bytes = File('tokenizer.model').readAsBytesSync();
/// final counter = await TokenCounter.forModel(LlmModel.gemini2Pro)
///     .loadSpVocab(BytesSpVocabLoader(bytes));
/// ```
class BytesSpVocabLoader extends SpVocabLoader {
  const BytesSpVocabLoader(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> load() async => bytes;
}
