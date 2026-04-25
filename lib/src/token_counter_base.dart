import 'chat_message.dart';
import 'heuristic_tokenizer.dart';
import 'llm_model.dart';
import 'model_pricing.dart';
import 'multimodal/image_token_estimator.dart';
import 'sentencepiece/sp_proto_reader.dart';
import 'sentencepiece/sp_unigram_encoder.dart';
import 'sentencepiece/sp_vocab_loader.dart';
import 'tiktoken/tiktoken_bpe_encoder.dart';
import 'tiktoken/tiktoken_patterns.dart';
import 'tiktoken/tiktoken_vocab_loader.dart';
import 'tiktoken/tiktoken_vocab_parser.dart';

/// Estimates the number of tokens a string (or chat conversation) consumes
/// when sent to a given LLM.
///
/// Three modes are supported:
///
/// - **Heuristic (default)**: Unicode script-based coefficients. No assets
///   required. Expect ±10–20 % error.
/// - **Exact tiktoken BPE** ([loadVocab]): `cl100k_base` / `o200k_base`
///   vocabulary for OpenAI models.
/// - **SentencePiece unigram LM** ([loadSpVocab]): `.model` file for
///   Gemini, Llama 2, and other SentencePiece-based models.
class TokenCounter {
  TokenCounter._({
    required this.model,
    required HeuristicTokenizer tokenizer,
    TiktokenBpeEncoder? bpeEncoder,
    SpUnigramEncoder? spEncoder,
  }) : _tokenizer = tokenizer,
       _bpeEncoder = bpeEncoder,
       _spEncoder = spEncoder;

  /// Creates a counter for [model] using the heuristic estimator.
  factory TokenCounter.forModel(LlmModel model) {
    return TokenCounter._(
      model: model,
      tokenizer: HeuristicTokenizer(model.family),
    );
  }

  /// Shortcut that estimates tokens using GPT-4o heuristic coefficients.
  static int estimate(String text, {LlmModel model = LlmModel.gpt4o}) =>
      TokenCounter.forModel(model).count(text);

  /// The model this counter targets.
  final LlmModel model;

  final HeuristicTokenizer _tokenizer;
  final TiktokenBpeEncoder? _bpeEncoder;
  final SpUnigramEncoder? _spEncoder;

  /// Whether this counter is using an exact encoder (tiktoken BPE or
  /// SentencePiece unigram LM) rather than the heuristic estimator.
  bool get isExact => _bpeEncoder != null || _spEncoder != null;

  // ---------------------------------------------------------------------------
  // Exact tiktoken BPE (v0.2)
  // ---------------------------------------------------------------------------

  /// Loads a tiktoken BPE vocabulary and returns a new [TokenCounter] backed
  /// by the exact encoder.
  ///
  /// Only supported for `cl100kBase` and `o200kBase` families (OpenAI models).
  /// Throws [ArgumentError] for other families.
  ///
  /// ```dart
  /// final bytes = File('o200k_base.tiktoken').readAsBytesSync();
  /// final counter = await TokenCounter.forModel(LlmModel.gpt4o)
  ///     .loadVocab(BytesVocabLoader(bytes),
  ///                specialTokens: TiktokenSpecialTokens.o200kBase);
  /// ```
  Future<TokenCounter> loadVocab(
    TiktokenVocabLoader loader, {
    Map<String, int> specialTokens = const {},
  }) async {
    final family = model.family;
    if (family != TokenizerFamily.o200kBase &&
        family != TokenizerFamily.cl100kBase) {
      throw ArgumentError(
        'loadVocab is only supported for tiktoken families '
        '(o200kBase, cl100kBase). Got: $family',
      );
    }
    final bytes = await loader.load();
    final vocab = TiktokenVocabParser.parse(bytes);
    final pattern = TiktokenPatterns.forFamily(family);
    final encoder = TiktokenBpeEncoder(
      vocab: vocab,
      pattern: pattern,
      specialTokens: specialTokens,
    );
    return TokenCounter._(
      model: model,
      tokenizer: _tokenizer,
      bpeEncoder: encoder,
    );
  }

  // ---------------------------------------------------------------------------
  // Exact SentencePiece (v0.3)
  // ---------------------------------------------------------------------------

  /// Loads a SentencePiece `.model` vocabulary and returns a new
  /// [TokenCounter] backed by the unigram-LM encoder.
  ///
  /// Supported for `gemini` and `llama` families. Throws [ArgumentError] for
  /// tiktoken families (`cl100kBase`, `o200kBase`) — use [loadVocab] instead.
  ///
  /// ```dart
  /// final bytes = File('tokenizer.model').readAsBytesSync();
  /// final counter = await TokenCounter.forModel(LlmModel.gemini2Pro)
  ///     .loadSpVocab(BytesSpVocabLoader(bytes));
  /// ```
  Future<TokenCounter> loadSpVocab(SpVocabLoader loader) async {
    final family = model.family;
    if (family == TokenizerFamily.o200kBase ||
        family == TokenizerFamily.cl100kBase) {
      throw ArgumentError(
        'loadSpVocab is not supported for tiktoken families. '
        'Use loadVocab instead.',
      );
    }
    final bytes = await loader.load();
    final pieces = SpProtoReader.readPieces(bytes);
    final encoder = SpUnigramEncoder(pieces);
    return TokenCounter._(
      model: model,
      tokenizer: _tokenizer,
      spEncoder: encoder,
    );
  }

  // ---------------------------------------------------------------------------
  // Core counting
  // ---------------------------------------------------------------------------

  /// Returns the number of tokens in [text].
  ///
  /// Priority: tiktoken BPE > SentencePiece > heuristic.
  int count(String text) {
    final bpe = _bpeEncoder;
    if (bpe != null) return bpe.count(text);
    final sp = _spEncoder;
    if (sp != null) return sp.count(text);
    return _tokenizer.count(text);
  }

  /// Returns the total tokens for a chat-style [messages] array including
  /// per-message role/separator overhead and any image attachments.
  ///
  /// Image token costs are calculated using [ImageTokenEstimator] for the
  /// appropriate provider.
  int countMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return 0;
    final overheadPerMessage = _overheadPerMessage(model.provider);
    final priming = _priming(model.provider);
    var total = priming;
    for (final message in messages) {
      total += overheadPerMessage;
      total += count(message.content);
      final name = message.name;
      if (name != null && name.isNotEmpty) {
        total += count(name) + 1;
      }
      for (final img in message.images) {
        total += _imageTokens(img);
      }
    }
    return total;
  }

  int _imageTokens(ImageAttachment img) {
    final flat = img.flatTokens;
    if (flat != null) return flat;
    final w = img.width;
    final h = img.height;
    if (w == null || h == null) return 0;
    switch (model.provider) {
      case LlmProvider.openai:
        return ImageTokenEstimator.openai(
          width: w,
          height: h,
          detail: img.detail,
        );
      case LlmProvider.anthropic:
        return ImageTokenEstimator.claude(width: w, height: h);
      case LlmProvider.google:
        return ImageTokenEstimator.gemini();
      case LlmProvider.meta:
        return ImageTokenEstimator.openai(width: w, height: h);
    }
  }

  /// Estimates the USD cost of a single call.
  double estimateCost({
    required int inputTokens,
    required int outputTokens,
    ModelPricing? pricing,
  }) {
    final resolved = pricing ?? ModelPricing.forModel(model);
    if (resolved == null) {
      throw StateError(
        'No bundled pricing for $model. Pass a ModelPricing explicitly.',
      );
    }
    return resolved.cost(inputTokens: inputTokens, outputTokens: outputTokens);
  }

  static int _overheadPerMessage(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.openai:
        return 4;
      case LlmProvider.anthropic:
        return 5;
      case LlmProvider.google:
        return 3;
      case LlmProvider.meta:
        return 4;
    }
  }

  static int _priming(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.openai:
        return 2;
      case LlmProvider.anthropic:
        return 0;
      case LlmProvider.google:
        return 0;
      case LlmProvider.meta:
        return 2;
    }
  }
}
