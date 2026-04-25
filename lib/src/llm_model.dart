/// Supported LLM model identifiers.
///
/// Each value carries metadata about the tokenizer family, provider, context
/// window size, and maximum output tokens.
enum LlmModel {
  // OpenAI — o200k_base family
  gpt4o(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 16384,
  ),
  gpt4oMini(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 16384,
  ),
  gpt4_1(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 1047576,
    maxOutputTokens: 32768,
  ),
  o1(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 200000,
    maxOutputTokens: 100000,
  ),
  o3(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 200000,
    maxOutputTokens: 100000,
  ),

  // OpenAI — cl100k_base family
  gpt4(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 8192,
    maxOutputTokens: 8192,
  ),
  gpt4Turbo(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 4096,
  ),
  gpt35Turbo(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 16385,
    maxOutputTokens: 4096,
  ),

  // Anthropic Claude
  claude3Haiku(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),
  claude3Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),
  claude3Opus(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),
  claude35Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 8192,
  ),
  claude37Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 128000,
  ),
  claude4Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 64000,
  ),
  claude4Opus(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 32000,
  ),

  // Google Gemini
  gemini15Flash(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 1048576,
    maxOutputTokens: 8192,
  ),
  gemini15Pro(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 2097152,
    maxOutputTokens: 8192,
  ),
  gemini2Flash(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 1048576,
    maxOutputTokens: 8192,
  ),
  gemini2Pro(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 2097152,
    maxOutputTokens: 8192,
  ),

  // Meta Llama
  llama3(
    family: TokenizerFamily.llama,
    provider: LlmProvider.meta,
    contextWindow: 8192,
    maxOutputTokens: 8192,
  ),
  llama31(
    family: TokenizerFamily.llama,
    provider: LlmProvider.meta,
    contextWindow: 131072,
    maxOutputTokens: 131072,
  ),
  llama33(
    family: TokenizerFamily.llama,
    provider: LlmProvider.meta,
    contextWindow: 131072,
    maxOutputTokens: 131072,
  );

  const LlmModel({
    required this.family,
    required this.provider,
    required this.contextWindow,
    required this.maxOutputTokens,
  });

  final TokenizerFamily family;
  final LlmProvider provider;

  /// Total context window size in tokens (input + output).
  final int contextWindow;

  /// Maximum number of output tokens this model can generate per call.
  final int maxOutputTokens;
}

/// Tokenizer families that share a vocabulary and similar ratios.
enum TokenizerFamily { o200kBase, cl100kBase, claude, gemini, llama }

enum LlmProvider { openai, anthropic, google, meta }
