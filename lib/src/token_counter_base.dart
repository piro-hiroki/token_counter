import 'chat_message.dart';
import 'heuristic_tokenizer.dart';
import 'llm_model.dart';
import 'model_pricing.dart';
import 'tiktoken/tiktoken_bpe_encoder.dart';
import 'tiktoken/tiktoken_patterns.dart';
import 'tiktoken/tiktoken_vocab_loader.dart';
import 'tiktoken/tiktoken_vocab_parser.dart';

/// Estimates the number of tokens a string (or chat conversation) consumes
/// when sent to a given LLM.
///
/// Two modes are supported:
///
/// - **Heuristic (default)**: Uses Unicode script-based coefficients derived
///   from published tokenizer benchmarks. No assets required. Expect ±10-20%
///   error versus the exact tokenizer.
/// - **Exact BPE**: Loads the real tiktoken vocabulary and runs the BPE
///   algorithm. Requires supplying the `.tiktoken` file via [loadVocab].
///   Supported for `cl100k_base` and `o200k_base` families (OpenAI models).
///
/// Basic usage:
///
/// ```dart
/// final counter = TokenCounter.forModel(LlmModel.gpt4o);
/// final tokens = counter.count('Hello, world!');
/// ```
///
/// Exact mode:
///
/// ```dart
/// // Caller provides the raw .tiktoken file bytes (from assets, file, etc.)
/// final counter = await TokenCounter.forModel(LlmModel.gpt4o)
///     .loadVocab(BytesVocabLoader(vocabBytes));
/// final tokens = counter.count('Hello, world!');
/// ```
class TokenCounter {
  TokenCounter._({
    required this.model,
    required HeuristicTokenizer tokenizer,
    TiktokenBpeEncoder? bpeEncoder,
  }) : _tokenizer = tokenizer,
       _bpeEncoder = bpeEncoder;

  /// Creates a counter for [model] using the heuristic estimator.
  factory TokenCounter.forModel(LlmModel model) {
    return TokenCounter._(
      model: model,
      tokenizer: HeuristicTokenizer(model.family),
    );
  }

  /// Shortcut that estimates tokens for [text] using GPT-4o coefficients.
  ///
  /// Convenient for quick one-off measurements when the exact model is
  /// unknown or irrelevant.
  static int estimate(String text, {LlmModel model = LlmModel.gpt4o}) {
    return TokenCounter.forModel(model).count(text);
  }

  /// The model this counter targets.
  final LlmModel model;

  final HeuristicTokenizer _tokenizer;
  final TiktokenBpeEncoder? _bpeEncoder;

  /// Whether this counter is running in exact BPE mode.
  bool get isExact => _bpeEncoder != null;

  /// Loads a tiktoken BPE vocabulary and returns a new [TokenCounter] backed
  /// by the exact encoder.
  ///
  /// [loader] provides the raw bytes of the `.tiktoken` vocabulary file.
  /// [specialTokens] is an optional map of special-token strings to their
  /// ranks (e.g. from [TiktokenSpecialTokens.cl100kBase]). Each occurrence
  /// of a special token in the input is counted as exactly 1 token.
  ///
  /// Throws [ArgumentError] if [model]'s tokenizer family is not tiktoken-
  /// compatible (`cl100kBase` or `o200kBase`).
  ///
  /// ```dart
  /// final bytes = File('o200k_base.tiktoken').readAsBytesSync();
  /// final counter = await TokenCounter.forModel(LlmModel.gpt4o)
  ///     .loadVocab(
  ///       BytesVocabLoader(bytes),
  ///       specialTokens: TiktokenSpecialTokens.o200kBase,
  ///     );
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

  /// Returns the number of tokens in [text].
  ///
  /// Uses exact BPE if [loadVocab] was called, otherwise uses the heuristic
  /// estimator.
  int count(String text) {
    final bpe = _bpeEncoder;
    if (bpe != null) return bpe.count(text);
    return _tokenizer.count(text);
  }

  /// Returns the total tokens for a chat-style [messages] array,
  /// including per-message role/separator overhead.
  ///
  /// - OpenAI: ~4 tokens per message + 2 priming tokens.
  /// - Anthropic: ~5 tokens per message.
  /// - Others: ~4 tokens per message.
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
    }
    return total;
  }

  /// Estimates the USD cost of a single call.
  ///
  /// If [pricing] is omitted, [ModelPricing.forModel] is used. Throws
  /// [StateError] if no pricing is available for [model] and none was
  /// supplied.
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
    return resolved.cost(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
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
