/// Supported LLM model identifiers.
///
/// Each value carries metadata about the tokenizer family, provider, context
/// window size, and maximum output tokens.
enum LlmModel {
  // -------------------------------------------------------------------------
  // OpenAI — o200k_base family
  // -------------------------------------------------------------------------

  /// GPT-4o (128 k context, o200k_base).
  gpt4o(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 16384,
  ),

  /// GPT-4o mini (128 k context, o200k_base).
  gpt4oMini(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 16384,
  ),

  /// GPT-4.1 (1 M context, o200k_base).
  gpt4_1(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 1047576,
    maxOutputTokens: 32768,
  ),

  /// o1 reasoning model (200 k context, o200k_base).
  o1(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 200000,
    maxOutputTokens: 100000,
  ),

  /// o3 reasoning model (200 k context, o200k_base).
  o3(
    family: TokenizerFamily.o200kBase,
    provider: LlmProvider.openai,
    contextWindow: 200000,
    maxOutputTokens: 100000,
  ),

  // -------------------------------------------------------------------------
  // OpenAI — cl100k_base family
  // -------------------------------------------------------------------------

  /// GPT-4 (8 k context, cl100k_base).
  gpt4(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 8192,
    maxOutputTokens: 8192,
  ),

  /// GPT-4 Turbo (128 k context, cl100k_base).
  gpt4Turbo(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 128000,
    maxOutputTokens: 4096,
  ),

  /// GPT-3.5 Turbo (16 k context, cl100k_base).
  gpt35Turbo(
    family: TokenizerFamily.cl100kBase,
    provider: LlmProvider.openai,
    contextWindow: 16385,
    maxOutputTokens: 4096,
  ),

  // -------------------------------------------------------------------------
  // Anthropic Claude
  // -------------------------------------------------------------------------

  /// Claude 3 Haiku (200 k context).
  claude3Haiku(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),

  /// Claude 3 Sonnet (200 k context).
  claude3Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),

  /// Claude 3 Opus (200 k context).
  claude3Opus(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 4096,
  ),

  /// Claude 3.5 Sonnet (200 k context).
  claude35Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 8192,
  ),

  /// Claude 3.7 Sonnet (200 k context, extended thinking).
  claude37Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 128000,
  ),

  /// Claude 4 Sonnet (200 k context).
  claude4Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 64000,
  ),

  /// Claude 4 Opus (200 k context).
  claude4Opus(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxOutputTokens: 32000,
  ),

  // -------------------------------------------------------------------------
  // Google Gemini
  // -------------------------------------------------------------------------

  /// Gemini 1.5 Flash (1 M context, SentencePiece).
  gemini15Flash(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 1048576,
    maxOutputTokens: 8192,
  ),

  /// Gemini 1.5 Pro (2 M context, SentencePiece).
  gemini15Pro(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 2097152,
    maxOutputTokens: 8192,
  ),

  /// Gemini 2 Flash (1 M context, SentencePiece).
  gemini2Flash(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 1048576,
    maxOutputTokens: 8192,
  ),

  /// Gemini 2 Pro (2 M context, SentencePiece).
  gemini2Pro(
    family: TokenizerFamily.gemini,
    provider: LlmProvider.google,
    contextWindow: 2097152,
    maxOutputTokens: 8192,
  ),

  // -------------------------------------------------------------------------
  // Meta Llama
  // -------------------------------------------------------------------------

  /// Llama 3 (8 k context).
  llama3(
    family: TokenizerFamily.llama,
    provider: LlmProvider.meta,
    contextWindow: 8192,
    maxOutputTokens: 8192,
  ),

  /// Llama 3.1 (128 k context).
  llama31(
    family: TokenizerFamily.llama,
    provider: LlmProvider.meta,
    contextWindow: 131072,
    maxOutputTokens: 131072,
  ),

  /// Llama 3.3 (128 k context).
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

  /// The tokenizer family used by this model.
  final TokenizerFamily family;

  /// The API provider for this model.
  final LlmProvider provider;

  /// Total context window size in tokens (input + output combined).
  final int contextWindow;

  /// Maximum number of output tokens this model can generate per call.
  final int maxOutputTokens;
}

/// Tokenizer families that share vocabulary and encoding behaviour.
enum TokenizerFamily {
  /// OpenAI `o200k_base` (GPT-4o, GPT-4.1, o-series).
  o200kBase,

  /// OpenAI `cl100k_base` (GPT-4, GPT-3.5-turbo).
  cl100kBase,

  /// Anthropic Claude (proprietary; heuristic mode only).
  claude,

  /// Google Gemini (SentencePiece unigram-LM).
  gemini,

  /// Meta Llama 3 (tiktoken-compatible BPE).
  llama,
}

/// LLM API providers.
enum LlmProvider {
  /// OpenAI (ChatGPT, GPT-4, o-series).
  openai,

  /// Anthropic (Claude family).
  anthropic,

  /// Google (Gemini family).
  google,

  /// Meta (Llama family).
  meta,
}
