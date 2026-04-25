import 'llm_model.dart';

/// Per-million-token pricing for input and output tokens, in USD.
///
/// Values reflect publicly posted list prices and may become stale. Override
/// with current numbers via the default constructor if needed.
class ModelPricing {
  /// Creates a [ModelPricing] with explicit per-million-token rates in USD.
  const ModelPricing({
    required this.inputPerMillion,
    required this.outputPerMillion,
  });

  /// Cost in USD per 1 000 000 input (prompt) tokens.
  final double inputPerMillion;

  /// Cost in USD per 1 000 000 output (completion) tokens.
  final double outputPerMillion;

  /// Returns the estimated cost in USD for the given token counts.
  double cost({required int inputTokens, required int outputTokens}) {
    return (inputTokens / 1e6) * inputPerMillion +
        (outputTokens / 1e6) * outputPerMillion;
  }

  /// Best-effort default pricing for a given model.
  ///
  /// Returns `null` if the model has no bundled pricing — callers should
  /// supply a [ModelPricing] instance explicitly in that case.
  static ModelPricing? forModel(LlmModel model) => _pricing[model];

  static const Map<LlmModel, ModelPricing> _pricing = {
    // OpenAI
    LlmModel.gpt4o: ModelPricing(inputPerMillion: 2.50, outputPerMillion: 10.00),
    LlmModel.gpt4oMini: ModelPricing(inputPerMillion: 0.15, outputPerMillion: 0.60),
    LlmModel.gpt4_1: ModelPricing(inputPerMillion: 2.00, outputPerMillion: 8.00),
    LlmModel.o1: ModelPricing(inputPerMillion: 15.00, outputPerMillion: 60.00),
    LlmModel.o3: ModelPricing(inputPerMillion: 10.00, outputPerMillion: 40.00),
    LlmModel.gpt4: ModelPricing(inputPerMillion: 30.00, outputPerMillion: 60.00),
    LlmModel.gpt4Turbo: ModelPricing(inputPerMillion: 10.00, outputPerMillion: 30.00),
    LlmModel.gpt35Turbo: ModelPricing(inputPerMillion: 0.50, outputPerMillion: 1.50),

    // Anthropic
    LlmModel.claude3Haiku: ModelPricing(inputPerMillion: 0.25, outputPerMillion: 1.25),
    LlmModel.claude3Sonnet: ModelPricing(inputPerMillion: 3.00, outputPerMillion: 15.00),
    LlmModel.claude3Opus: ModelPricing(inputPerMillion: 15.00, outputPerMillion: 75.00),
    LlmModel.claude35Sonnet: ModelPricing(inputPerMillion: 3.00, outputPerMillion: 15.00),
    LlmModel.claude37Sonnet: ModelPricing(inputPerMillion: 3.00, outputPerMillion: 15.00),
    LlmModel.claude4Sonnet: ModelPricing(inputPerMillion: 3.00, outputPerMillion: 15.00),
    LlmModel.claude4Opus: ModelPricing(inputPerMillion: 15.00, outputPerMillion: 75.00),

    // Google
    LlmModel.gemini15Flash: ModelPricing(inputPerMillion: 0.075, outputPerMillion: 0.30),
    LlmModel.gemini15Pro: ModelPricing(inputPerMillion: 1.25, outputPerMillion: 5.00),
    LlmModel.gemini2Flash: ModelPricing(inputPerMillion: 0.10, outputPerMillion: 0.40),
    LlmModel.gemini2Pro: ModelPricing(inputPerMillion: 1.25, outputPerMillion: 5.00),

    // Meta (typical hosted pricing; self-hosted = free)
    LlmModel.llama3: ModelPricing(inputPerMillion: 0.20, outputPerMillion: 0.20),
    LlmModel.llama31: ModelPricing(inputPerMillion: 0.20, outputPerMillion: 0.20),
    LlmModel.llama33: ModelPricing(inputPerMillion: 0.20, outputPerMillion: 0.20),
  };
}
