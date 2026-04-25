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
