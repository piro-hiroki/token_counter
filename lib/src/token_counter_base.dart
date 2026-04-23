import 'chat_message.dart';
import 'heuristic_tokenizer.dart';
import 'llm_model.dart';
import 'model_pricing.dart';

/// Estimates the number of tokens a string (or chat conversation) consumes
/// when sent to a given LLM.
///
/// Two modes are supported:
///
/// - **Heuristic (default)**: Uses Unicode script-based coefficients derived
///   from published tokenizer benchmarks. No assets required. Expect ±10-20%
///   error versus the exact tokenizer.
/// - **Accurate (future)**: Loads the real BPE / SentencePiece vocabulary for
///   the model. Planned for v0.2+ (tiktoken-compatible) and v0.3+ (Claude /
///   Gemini SentencePiece).
///
/// Basic usage:
///
/// ```dart
/// final counter = TokenCounter.forModel(LlmModel.gpt4o);
/// final tokens = counter.count('Hello, world!');
/// ```
class TokenCounter {
  TokenCounter._({required this.model, required HeuristicTokenizer tokenizer})
    : _tokenizer = tokenizer;

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

  /// Returns the estimated number of tokens in [text].
  int count(String text) => _tokenizer.count(text);

  /// Returns the estimated total tokens for a chat-style [messages] array,
  /// including per-message role/separator overhead.
  ///
  /// Overhead approximates the reference implementations:
  ///
  /// - OpenAI chat: ~4 tokens per message (role, separators) + 2 priming.
  /// - Anthropic: ~5 tokens per message (Human:/Assistant: framing).
  /// - Others: conservative 4-token approximation.
  int countMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return 0;

    final overheadPerMessage = _overheadPerMessage(model.provider);
    final priming = _priming(model.provider);

    var total = priming;
    for (final message in messages) {
      total += overheadPerMessage;
      total += _tokenizer.count(message.content);
      final name = message.name;
      if (name != null && name.isNotEmpty) {
        total += _tokenizer.count(name) + 1;
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
