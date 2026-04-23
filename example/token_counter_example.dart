// Example usage of the token_counter package.
//
// Run with: dart run example/token_counter_example.dart
import 'package:token_counter/token_counter.dart';

void main() {
  // 1. Quickest path — default GPT-4o heuristic.
  final quick = TokenCounter.estimate('Hello, world!');
  print('Quick estimate: $quick tokens');

  // 2. Pick a specific model.
  final claude = TokenCounter.forModel(LlmModel.claude4Sonnet);
  final ja = claude.count('日本語のトークン数を計測してみよう。');
  print('Claude 4 Sonnet (Japanese): $ja tokens');

  // 3. Compare tokenizer families on the same text.
  const mixed = 'Hello, こんにちは, 안녕하세요, 你好!';
  for (final model in [
    LlmModel.gpt4o,
    LlmModel.gpt4,
    LlmModel.claude4Sonnet,
    LlmModel.gemini2Pro,
    LlmModel.llama31,
  ]) {
    final n = TokenCounter.forModel(model).count(mixed);
    print('${model.name.padRight(18)} $n tokens');
  }

  // 4. Chat-style messages with per-message overhead.
  final counter = TokenCounter.forModel(LlmModel.gpt4o);
  final total = counter.countMessages([
    const ChatMessage.system('You are a helpful assistant.'),
    const ChatMessage.user('東京の天気は？'),
    const ChatMessage.assistant('今日の東京は晴れ時々曇り、最高気温18度です。'),
  ]);
  print('Chat total: $total tokens');

  // 5. Cost estimation.
  final cost = counter.estimateCost(inputTokens: total, outputTokens: 300);
  print('Estimated cost: \$${cost.toStringAsFixed(6)}');
}
