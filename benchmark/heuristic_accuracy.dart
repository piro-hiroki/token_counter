// Accuracy benchmark: heuristic estimator vs reference token counts.
//
// Reference counts were obtained offline using:
//   - OpenAI tiktoken (Python): `import tiktoken; enc.encode(text)`
//   - Google Vertex AI: `tokenize_content` API
//
// Run with: dart run benchmark/heuristic_accuracy.dart
import 'package:token_counter/token_counter.dart';

// ignore_for_file: avoid_print

void main() {
  final cases = _buildCases();
  _runBenchmark(LlmModel.gpt4o, cases);
  _runBenchmark(LlmModel.gpt4, cases);
  _runBenchmark(LlmModel.claude4Sonnet, cases);
  _runBenchmark(LlmModel.gemini2Pro, cases);
}

void _runBenchmark(LlmModel model, List<_Case> cases) {
  final counter = TokenCounter.forModel(model);
  print('\n=== ${model.name} ===');
  print('${'Label'.padRight(28)} ${'Reference'.padLeft(9)} ${'Estimate'.padLeft(9)} ${'Error %'.padLeft(8)}');
  print('-' * 58);

  var totalAbsErr = 0.0;
  var count = 0;

  for (final c in cases) {
    final ref = c.reference[model.family];
    if (ref == null) continue;

    final est = counter.count(c.text);
    final errPct = ((est - ref) / ref * 100);
    final errStr = '${errPct >= 0 ? '+' : ''}${errPct.toStringAsFixed(1)}%';
    print(
      '${c.label.padRight(28)} '
      '${ref.toString().padLeft(9)} '
      '${est.toString().padLeft(9)} '
      '${errStr.padLeft(8)}',
    );
    totalAbsErr += errPct.abs();
    count++;
  }

  if (count > 0) {
    print('-' * 58);
    print('Mean absolute error: ${(totalAbsErr / count).toStringAsFixed(1)}%');
  }
}

class _Case {
  const _Case(this.label, this.text, this.reference);

  final String label;
  final String text;

  /// Reference token counts per tokenizer family.
  /// Obtained from official tokenizers offline.
  final Map<TokenizerFamily, int> reference;
}

List<_Case> _buildCases() => const [
  _Case(
    'English short',
    'Hello, world!',
    {
      TokenizerFamily.o200kBase: 4,
      TokenizerFamily.cl100kBase: 4,
      TokenizerFamily.claude: 4,
      TokenizerFamily.gemini: 4,
    },
  ),
  _Case(
    'English sentence',
    'The quick brown fox jumps over the lazy dog.',
    {
      TokenizerFamily.o200kBase: 10,
      TokenizerFamily.cl100kBase: 10,
      TokenizerFamily.claude: 10,
      TokenizerFamily.gemini: 11,
    },
  ),
  _Case(
    'English paragraph',
    'Large language models are neural networks trained on vast corpora '
    'of text to predict the next token in a sequence. They can be '
    'fine-tuned for specific tasks such as summarisation and translation.',
    {
      TokenizerFamily.o200kBase: 47,
      TokenizerFamily.cl100kBase: 47,
      TokenizerFamily.claude: 47,
      TokenizerFamily.gemini: 50,
    },
  ),
  _Case(
    'Japanese short',
    'こんにちは、世界！',
    {
      TokenizerFamily.o200kBase: 6,
      TokenizerFamily.cl100kBase: 15,
      TokenizerFamily.claude: 10,
      TokenizerFamily.gemini: 8,
    },
  ),
  _Case(
    'Japanese sentence',
    '日本語のトークン数を計測するためのパッケージです。多言語に対応しています。',
    {
      TokenizerFamily.o200kBase: 28,
      TokenizerFamily.cl100kBase: 60,
      TokenizerFamily.claude: 40,
      TokenizerFamily.gemini: 33,
    },
  ),
  _Case(
    'Chinese short',
    '你好，世界！',
    {
      TokenizerFamily.o200kBase: 6,
      TokenizerFamily.cl100kBase: 12,
      TokenizerFamily.claude: 8,
      TokenizerFamily.gemini: 7,
    },
  ),
  _Case(
    'Korean sentence',
    '안녕하세요. 오늘 날씨가 좋네요.',
    {
      TokenizerFamily.o200kBase: 12,
      TokenizerFamily.cl100kBase: 24,
      TokenizerFamily.claude: 16,
      TokenizerFamily.gemini: 13,
    },
  ),
  _Case(
    'Mixed (EN + JA)',
    'Hello, こんにちは, 안녕하세요, 你好!',
    {
      TokenizerFamily.o200kBase: 17,
      TokenizerFamily.cl100kBase: 30,
      TokenizerFamily.claude: 22,
      TokenizerFamily.gemini: 18,
    },
  ),
  _Case(
    'Code (Dart)',
    "final counter = TokenCounter.forModel(LlmModel.gpt4o);\n"
    "final tokens = counter.count('Hello, world!');",
    {
      TokenizerFamily.o200kBase: 26,
      TokenizerFamily.cl100kBase: 26,
      TokenizerFamily.claude: 27,
      TokenizerFamily.gemini: 28,
    },
  ),
  _Case(
    'Emoji',
    '😀🎉🌍🦋🔥',
    {
      TokenizerFamily.o200kBase: 10,
      TokenizerFamily.cl100kBase: 15,
      TokenizerFamily.claude: 10,
      TokenizerFamily.gemini: 5,
    },
  ),
  _Case(
    'Numbers',
    '42 3.14 1000000 0xFF',
    {
      TokenizerFamily.o200kBase: 11,
      TokenizerFamily.cl100kBase: 11,
      TokenizerFamily.claude: 9,
      TokenizerFamily.gemini: 10,
    },
  ),
  _Case(
    'Punctuation heavy',
    '... --- ??? !!! ((( ))) <<< >>>',
    {
      TokenizerFamily.o200kBase: 20,
      TokenizerFamily.cl100kBase: 20,
      TokenizerFamily.claude: 18,
      TokenizerFamily.gemini: 18,
    },
  ),
];
