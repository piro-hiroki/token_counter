# token_counter

A pure-Dart token estimator for popular large language models. Works on all Flutter platforms (iOS, Android, macOS, Windows, Linux, Web) and on the Dart VM — no FFI, no native code, no vocabulary files required.

[![pub.dev](https://img.shields.io/pub/v/token_counter.svg)](https://pub.dev/packages/token_counter)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Multi-provider support** — OpenAI (GPT-4o, GPT-4, o-series), Anthropic Claude 3–4, Google Gemini 1.5/2, Meta Llama 3.x
- **Multi-language accuracy** — per-script Unicode coefficients for Latin, CJK, Hiragana, Katakana, Hangul, Arabic, Cyrillic, Devanagari, Thai, emoji, and more
- **Chat-message overhead** — role tokens and separator framing included per provider
- **Cost estimation** — bundled pricing table, or supply your own
- **Zero dependencies** — pure Dart, no assets needed in the default heuristic mode

## Installation

```yaml
dependencies:
  token_counter: ^0.1.1
```

## Usage

### Quick estimate

```dart
import 'package:token_counter/token_counter.dart';

// One-liner — uses GPT-4o coefficients by default
final tokens = TokenCounter.estimate('Hello, world!');
```

### Pick a specific model

```dart
final counter = TokenCounter.forModel(LlmModel.claude4Sonnet);
final tokens = counter.count('東京の天気は？');
```

### Count chat-style messages

Per-message role overhead (e.g. `Human:` / `Assistant:` framing, OpenAI `<|im_start|>` tokens) is included automatically.

```dart
final counter = TokenCounter.forModel(LlmModel.gpt4o);

final total = counter.countMessages([
  const ChatMessage.system('You are a helpful assistant.'),
  const ChatMessage.user('What is the capital of Japan?'),
  const ChatMessage.assistant('The capital of Japan is Tokyo.'),
]);
```

### Estimate cost

```dart
final counter = TokenCounter.forModel(LlmModel.gpt4o);

// Uses the bundled pricing table
final cost = counter.estimateCost(
  inputTokens: 1500,
  outputTokens: 300,
);

// Or supply your own rates (USD per 1 million tokens)
final cost2 = counter.estimateCost(
  inputTokens: 1500,
  outputTokens: 300,
  pricing: const ModelPricing(inputPerMillion: 2.50, outputPerMillion: 10.00),
);
```

### Compare across models

```dart
const text = 'Hello, こんにちは, 안녕하세요, 你好!';

for (final model in [
  LlmModel.gpt4o,
  LlmModel.gpt4,
  LlmModel.claude4Sonnet,
  LlmModel.gemini2Pro,
  LlmModel.llama31,
]) {
  final n = TokenCounter.forModel(model).count(text);
  print('${model.name}: $n tokens');
}
```

## Supported models

| Provider  | Models | Tokenizer family |
|-----------|--------|-----------------|
| OpenAI | GPT-4o, GPT-4.1, o1, o3 | `o200k_base` |
| OpenAI | GPT-4, GPT-4 Turbo, GPT-3.5 Turbo | `cl100k_base` |
| Anthropic | Claude 3 Haiku / Sonnet / Opus, Claude 3.5 / 3.7 / 4 | Claude |
| Google | Gemini 1.5 Flash/Pro, Gemini 2 Flash/Pro | Gemini |
| Meta | Llama 3, 3.1, 3.3 | Llama |

All models use the **heuristic estimator** (Unicode script-based coefficients). Expect ±10–20 % error versus the exact tokenizer output. Exact BPE / SentencePiece implementations are planned for future releases.

## Accuracy vs. bundle size

Shipping real vocabulary files (BPE merges, SentencePiece models) would add several MB per model to your app's binary. `token_counter` avoids this by using Unicode-script coefficients derived from public tokenizer benchmarks — no assets required, negligible overhead.

When tighter bounds are needed, a vocabulary-loading API (`loadVocab`) is planned for v0.2+ (tiktoken) and v0.3+ (SentencePiece / Claude / Gemini).

## Roadmap

- [x] v0.1 — Heuristic estimator, 5 tokenizer families, 24 models, pricing table
- [ ] v0.2 — Exact tiktoken BPE (`cl100k_base`, `o200k_base`) in pure Dart
- [ ] v0.3 — SentencePiece-compatible tokenizer (Claude / Gemini) in pure Dart
- [ ] v0.4 — Image and tool-call token overhead
- [ ] v1.0 — Benchmarks against official tokenizer APIs, stable release

## License

MIT
