/// Token counter for popular LLMs (OpenAI, Anthropic, Google, Meta) with
/// multi-language support. Pure Dart, works on all Flutter platforms and on
/// the Dart VM.
///
/// ## Entry points
///
/// - [TokenCounter] — create a counter, count tokens, estimate cost.
/// - [LlmModel] — choose a model (GPT-4o, Claude 4, Gemini 2, …).
/// - [ChatMessage] / [ImageAttachment] — build chat conversations.
/// - [ImageTokenEstimator] — standalone image token formulas.
/// - [ToolTokenEstimator] — estimate tool/function definition overhead.
/// - [ModelPricing] — per-million-token pricing.
///
/// ## Exact tokenization
///
/// - Tiktoken (OpenAI): [BytesVocabLoader], [TiktokenSpecialTokens]
///   → pass to [TokenCounter.loadVocab].
/// - SentencePiece (Gemini, Llama 2): [BytesSpVocabLoader]
///   → pass to [TokenCounter.loadSpVocab].
library;

export 'src/chat_message.dart';
export 'src/llm_model.dart';
export 'src/model_pricing.dart';
export 'src/multimodal/image_token_estimator.dart';
export 'src/multimodal/tool_token_estimator.dart';
export 'src/sentencepiece/sp_vocab_loader.dart';
export 'src/tiktoken/tiktoken_patterns.dart' show TiktokenSpecialTokens;
export 'src/tiktoken/tiktoken_vocab_loader.dart';
export 'src/token_counter_base.dart';
