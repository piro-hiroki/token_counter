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
