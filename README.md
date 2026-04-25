# token_counter

A pure-Dart token estimator for popular large language models. Works on all Flutter platforms (iOS, Android, macOS, Windows, Linux, Web) and on the Dart VM — no FFI, no native code.

[![pub.dev](https://img.shields.io/pub/v/token_counter.svg)](https://pub.dev/packages/token_counter)
[![CI](https://github.com/piro-hiroki/token_counter/actions/workflows/ci.yml/badge.svg)](https://github.com/piro-hiroki/token_counter/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Multi-provider support** — OpenAI (GPT-4o, GPT-4, o-series), Anthropic Claude 3–4, Google Gemini 1.5/2, Meta Llama 3.x
- **Multi-language accuracy** — per-script Unicode coefficients for Latin, CJK, Hiragana, Katakana, Hangul, Arabic, Cyrillic, Devanagari, Thai, emoji, and more
- **Exact tiktoken BPE** — load `cl100k_base` / `o200k_base` vocabulary files for byte-exact OpenAI token counts
- **Exact SentencePiece** — load `.model` files for Gemini, Llama 2, and other SentencePiece models
- **Image token costs** — provider-specific formulas (OpenAI tile-based, Claude pixel area, Gemini flat rate)
- **Tool/function overhead** — estimates token cost of tool definitions
- **Context window utilities** — `fitsInContext`, `remainingContextTokens`, `truncate`
- **Cost estimation** — bundled pricing table for all supported models
- **Zero pub dependencies** — pure Dart, no assets needed in heuristic mode

## Installation

```yaml
dependencies:
  token_counter: ^1.0.0
```

## Usage

### Quick estimate (heuristic, no setup required)

```dart
import 'package:token_counter/token_counter.dart';

// One-liner — uses GPT-4o coefficients by default
final tokens = TokenCounter.estimate('Hello, world!');

// Pick a specific model
final counter = TokenCounter.forModel(LlmModel.claude4Sonnet);
final tokens = counter.count('東京の天気は？');
```

### Exact tiktoken BPE (OpenAI models)

Vocabulary files can be downloaded from OpenAI's public CDN:
- `cl100k_base` (GPT-4, GPT-3.5): `https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken`
- `o200k_base` (GPT-4o, GPT-4.1, o-series): `https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken`

```dart
// Load bytes from a file, Flutter asset, network, etc.
final bytes = File('o200k_base.tiktoken').readAsBytesSync();

final counter = await TokenCounter.forModel(LlmModel.gpt4o).loadVocab(
  BytesVocabLoader(bytes),
  specialTokens: TiktokenSpecialTokens.o200kBase,
);

print(counter.isExact);           // true
print(counter.count('Hello!'));   // exact BPE token count
```

### Exact SentencePiece (Gemini, Llama 2, and others)

```dart
final bytes = File('tokenizer.model').readAsBytesSync();

final counter = await TokenCounter.forModel(LlmModel.gemini2Pro)
    .loadSpVocab(BytesSpVocabLoader(bytes));

print(counter.count('Hello, world!'));
```

### Chat messages with per-message overhead

```dart
final counter = TokenCounter.forModel(LlmModel.gpt4o);

final total = counter.countMessages([
  const ChatMessage.system('You are a helpful assistant.'),
  const ChatMessage.user('What is the capital of Japan?'),
  const ChatMessage.assistant('The capital of Japan is Tokyo.'),
]);
```

### Vision — image token costs

```dart
// OpenAI tile-based formula
final imgTokens = ImageTokenEstimator.openai(
  width: 1024,
  height: 768,
  detail: ImageDetail.high,
);

// Pass images directly in chat messages
final total = counter.countMessages([
  const ChatMessage.user(
    'What is in this image?',
    images: [ImageAttachment(width: 1024, height: 768)],
  ),
]);
```

### Tool / function overhead

```dart
final tokens = ToolTokenEstimator.estimate(
  model: LlmModel.gpt4o,
  tools: [
    {
      'type': 'function',
      'function': {
        'name': 'get_weather',
        'description': 'Get current weather for a city.',
        'parameters': {
          'type': 'object',
          'properties': {
            'city': {'type': 'string'},
          },
        },
      },
    },
  ],
);
```

### Context window utilities

```dart
final counter = TokenCounter.forModel(LlmModel.gpt4o);

// Check if content fits
if (!counter.fitsInContext(prompt)) {
  // How many tokens are left after placing prompt, reserving 1 000 for output
  final remaining = counter.remainingContextTokens(
    prompt,
    reserveForOutput: 1000,
  );
  // Truncate to fit
  prompt = counter.truncate(prompt, remaining);
}

// Context window and max output for any model
print(LlmModel.gpt4o.contextWindow);     // 128000
print(LlmModel.gemini15Pro.contextWindow); // 2097152
```

### Cost estimation

```dart
final counter = TokenCounter.forModel(LlmModel.gpt4o);

// Uses bundled pricing table
final cost = counter.estimateCost(inputTokens: 1500, outputTokens: 300);

// Override with custom rates (USD per 1 million tokens)
final cost2 = counter.estimateCost(
  inputTokens: 1500,
  outputTokens: 300,
  pricing: const ModelPricing(inputPerMillion: 2.50, outputPerMillion: 10.00),
);
```

## Supported models

| Provider  | Models | Tokenizer |
|-----------|--------|-----------|
| OpenAI | GPT-4o, GPT-4.1, o1, o3, GPT-4o mini | `o200k_base` |
| OpenAI | GPT-4, GPT-4 Turbo, GPT-3.5 Turbo | `cl100k_base` |
| Anthropic | Claude 3 Haiku/Sonnet/Opus, Claude 3.5/3.7/4 | Claude (heuristic) |
| Google | Gemini 1.5 Flash/Pro, Gemini 2 Flash/Pro | SentencePiece / heuristic |
| Meta | Llama 3, 3.1, 3.3 | tiktoken-compatible / heuristic |

The **heuristic estimator** (default, no setup) expects ±10–20 % error. Load a vocabulary file with `loadVocab` or `loadSpVocab` for byte-exact counts.

## Heuristic accuracy

Benchmarked against reference counts from the official tiktoken Python library and the Vertex AI `tokenize_content` API on 12 representative inputs (English, Japanese, Chinese, Korean, mixed, code, emoji, numbers, punctuation).

| Model family | Mean absolute error |
|---|---|
| `o200k_base` (GPT-4o) | ~15 % |
| `cl100k_base` (GPT-4) | ~28 % |
| Claude | ~18 % |
| Gemini | ~24 % |

Common outliers: digit-only strings (tiktoken chunks `1000000` into many 1-digit tokens) and punctuation runs (similarly fragmented). Mixed-script text containing CJK + Latin is typically within 15 %.

Run the benchmark yourself:

```bash
dart run benchmark/heuristic_accuracy.dart
```

## Accuracy vs. bundle size

Shipping real vocabulary files (BPE merges, SentencePiece models) would add several MB per model to your binary. `token_counter` avoids this by using Unicode-script coefficients in heuristic mode — no assets required, negligible overhead. Switch to exact mode when you need tight bounds.

## Roadmap

- [x] v0.1 — Heuristic estimator, 5 tokenizer families, 24 models, pricing table
- [x] v0.2 — Exact tiktoken BPE (`cl100k_base`, `o200k_base`) in pure Dart
- [x] v0.3 — SentencePiece unigram-LM tokenizer in pure Dart
- [x] v0.4 — Image token costs and tool/function overhead
- [x] v0.5 — Context window properties, `fitsInContext`, `remainingContextTokens`, `truncate`
- [x] v1.0 — API documentation, benchmarks, stable release

## License

MIT
