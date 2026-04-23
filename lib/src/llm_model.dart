/// Supported LLM model identifiers.
///
/// Each value carries metadata about which tokenizer family to use and how
/// chat-message overhead is applied.
enum LlmModel {
  // OpenAI — o200k_base family
  gpt4o(family: TokenizerFamily.o200kBase, provider: LlmProvider.openai),
  gpt4oMini(family: TokenizerFamily.o200kBase, provider: LlmProvider.openai),
  gpt4_1(family: TokenizerFamily.o200kBase, provider: LlmProvider.openai),
  o1(family: TokenizerFamily.o200kBase, provider: LlmProvider.openai),
  o3(family: TokenizerFamily.o200kBase, provider: LlmProvider.openai),

  // OpenAI — cl100k_base family
  gpt4(family: TokenizerFamily.cl100kBase, provider: LlmProvider.openai),
  gpt4Turbo(family: TokenizerFamily.cl100kBase, provider: LlmProvider.openai),
  gpt35Turbo(family: TokenizerFamily.cl100kBase, provider: LlmProvider.openai),

  // Anthropic Claude
  claude3Haiku(family: TokenizerFamily.claude, provider: LlmProvider.anthropic),
  claude3Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
  ),
  claude3Opus(family: TokenizerFamily.claude, provider: LlmProvider.anthropic),
  claude35Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
  ),
  claude37Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
  ),
  claude4Sonnet(
    family: TokenizerFamily.claude,
    provider: LlmProvider.anthropic,
  ),
  claude4Opus(family: TokenizerFamily.claude, provider: LlmProvider.anthropic),

  // Google Gemini
  gemini15Flash(family: TokenizerFamily.gemini, provider: LlmProvider.google),
  gemini15Pro(family: TokenizerFamily.gemini, provider: LlmProvider.google),
  gemini2Flash(family: TokenizerFamily.gemini, provider: LlmProvider.google),
  gemini2Pro(family: TokenizerFamily.gemini, provider: LlmProvider.google),

  // Meta Llama
  llama3(family: TokenizerFamily.llama, provider: LlmProvider.meta),
  llama31(family: TokenizerFamily.llama, provider: LlmProvider.meta),
  llama33(family: TokenizerFamily.llama, provider: LlmProvider.meta);

  const LlmModel({required this.family, required this.provider});

  final TokenizerFamily family;
  final LlmProvider provider;
}

/// Tokenizer families that share a vocabulary and similar ratios.
enum TokenizerFamily { o200kBase, cl100kBase, claude, gemini, llama }

enum LlmProvider { openai, anthropic, google, meta }
