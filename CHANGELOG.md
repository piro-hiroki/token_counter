## 0.4.0

- New `ImageTokenEstimator` with provider-specific formulas:
  - **OpenAI**: tile-based (512 px tiles, 170 tokens/tile + 85 base); `ImageDetail.low/high/auto`
  - **Anthropic Claude**: `width × height / 750`
  - **Google Gemini**: flat 258 tokens per image
- New `ToolTokenEstimator.estimate` for function/tool definition token overhead.
- `ChatMessage` now accepts an `images` list of `ImageAttachment` values.
- `TokenCounter.countMessages` automatically adds image token costs per provider.
- `ImageAttachment.flatTokens` override for when pixel dimensions are unknown.
- 14 new unit tests for image formulas, tool estimation, and message counting.

## 0.3.0

- Added SentencePiece unigram-LM tokenizer in pure Dart.
- New `SpProtoReader` — minimal protobuf decoder for `.model` files (no
  generated code, no native dependencies).
- New `SpUnigramEncoder` — Viterbi forward-pass segmentation.
- New `SpVocabLoader` abstract class + `BytesSpVocabLoader` implementation.
- New `TokenCounter.loadSpVocab(SpVocabLoader)` — switches the counter to
  exact SentencePiece mode for `gemini`, `llama`, and `claude` families.
- `TokenCounter.isExact` now returns `true` for both tiktoken BPE and
  SentencePiece modes.
- 8 new unit tests (proto parsing, Viterbi segmentation, `loadSpVocab` API).

## 0.2.0

- Added exact tiktoken BPE encoder for `cl100k_base` (GPT-4, GPT-3.5-turbo)
  and `o200k_base` (GPT-4o, GPT-4.1, o-series) vocabulary families.
- New `TokenCounter.loadVocab(TiktokenVocabLoader)` — supply the raw
  `.tiktoken` file bytes from any source (Flutter assets, local file,
  in-memory bytes) to switch the counter into exact mode.
- New `TiktokenVocabLoader` abstract class + `BytesVocabLoader` implementation.
- New `TiktokenVocabParser` for parsing the `.tiktoken` line format.
- New `TiktokenSpecialTokens` constants for `cl100k_base` and `o200k_base`.
- `TokenCounter.isExact` property to distinguish heuristic from BPE mode.
- 13 new unit tests for the BPE algorithm (merge correctness, special tokens,
  pre-tokenization, `loadVocab` API).

## 0.1.1

- Rewrote README in English with accurate, runnable code examples.
- Updated roadmap to mark v0.1 as complete.

## 0.1.0

Initial public release.

- Pure-Dart heuristic token estimator for OpenAI (GPT-4o / GPT-4 / o-series),
  Anthropic Claude 3–4, Google Gemini 1.5 / 2, and Meta Llama 3 / 3.1 / 3.3.
- Unicode script classifier covering Latin, CJK, Hiragana, Katakana, Hangul,
  Arabic, Cyrillic, Devanagari, Thai, emoji, and more.
- `TokenCounter.estimate`, `TokenCounter.forModel`, `countMessages`, and
  `estimateCost` public API.
- Bundled per-model pricing table for cost estimation.
- 22 unit tests covering multilingual inputs, per-provider chat overhead,
  and cost math.
