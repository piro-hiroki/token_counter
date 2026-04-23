import 'package:flutter/material.dart';
import 'package:token_counter/token_counter.dart';

void main() {
  runApp(const TokenCounterDemoApp());
}

class TokenCounterDemoApp extends StatelessWidget {
  const TokenCounterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'token_counter demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TokenCounterPage(),
    );
  }
}

class TokenCounterPage extends StatefulWidget {
  const TokenCounterPage({super.key});

  @override
  State<TokenCounterPage> createState() => _TokenCounterPageState();
}

class _TokenCounterPageState extends State<TokenCounterPage> {
  static const _initialText =
      'Hello, world!\n'
      'こんにちは、世界。\n'
      '안녕하세요, 세계.\n'
      '你好，世界。';

  final TextEditingController _controller = TextEditingController(
    text: _initialText,
  );

  LlmModel _selectedModel = LlmModel.gpt4o;

  static const List<LlmModel> _featuredModels = [
    LlmModel.gpt4o,
    LlmModel.gpt4oMini,
    LlmModel.gpt4,
    LlmModel.o3,
    LlmModel.claude4Sonnet,
    LlmModel.claude4Opus,
    LlmModel.claude35Sonnet,
    LlmModel.gemini2Pro,
    LlmModel.gemini2Flash,
    LlmModel.llama31,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final counter = TokenCounter.forModel(_selectedModel);
    final tokens = counter.count(text);
    final pricing = ModelPricing.forModel(_selectedModel);
    final cost = pricing?.cost(inputTokens: tokens, outputTokens: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('token_counter demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<LlmModel>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final m in _featuredModels)
                  DropdownMenuItem(value: m, child: Text(m.name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedModel = value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _StatsCard(
              characters: text.length,
              tokens: tokens,
              costUsd: cost,
            ),
            const SizedBox(height: 16),
            _ModelComparison(text: text),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.characters,
    required this.tokens,
    required this.costUsd,
  });

  final int characters;
  final int tokens;
  final double? costUsd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Chars', value: '$characters'),
            _Stat(label: 'Tokens', value: '$tokens'),
            _Stat(
              label: 'Input cost',
              value: costUsd == null
                  ? '—'
                  : '\$${costUsd!.toStringAsFixed(6)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

class _ModelComparison extends StatelessWidget {
  const _ModelComparison({required this.text});

  final String text;

  static const List<LlmModel> _models = [
    LlmModel.gpt4o,
    LlmModel.gpt4,
    LlmModel.claude4Sonnet,
    LlmModel.gemini2Pro,
    LlmModel.llama31,
  ];

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final m in _models)
        (
          model: m,
          tokens: TokenCounter.forModel(m).count(text),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Compare across models',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 4),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.model.name),
                    Text('${row.tokens} tokens'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
