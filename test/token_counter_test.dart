import 'package:test/test.dart';
import 'package:token_counter/token_counter.dart';

void main() {
  group('TokenCounter.estimate', () {
    test('returns 0 for empty string', () {
      expect(TokenCounter.estimate(''), 0);
    });

    test('returns at least 1 for non-empty input', () {
      expect(TokenCounter.estimate('a'), greaterThanOrEqualTo(1));
    });

    test('English is cheaper than Japanese per character', () {
      const english = 'The quick brown fox jumps over the lazy dog.';
      const japanese = '素早い茶色の狐が怠惰な犬を飛び越える。';

      final enTokens = TokenCounter.estimate(english);
      final jaTokens = TokenCounter.estimate(japanese);

      final enRatio = enTokens / english.length;
      final jaRatio = jaTokens / japanese.length;
      expect(jaRatio, greaterThan(enRatio));
    });

    test('Chinese kanji cost more than English letters for same char count',
        () {
      const chinese = '人工智能语言模型词汇测试用例字符串示例文本';
      const english = 'aaaaaaaaaaaaaaaaaaaa';

      expect(
        TokenCounter.estimate(chinese),
        greaterThan(TokenCounter.estimate(english)),
      );
    });
  });

  group('TokenCounter.forModel', () {
    test('different families produce different estimates', () {
      const text = '日本語のテストです。';
      final gpt4o = TokenCounter.forModel(LlmModel.gpt4o).count(text);
      final gpt4 = TokenCounter.forModel(LlmModel.gpt4).count(text);

      expect(gpt4, greaterThan(gpt4o));
    });

    test('count is deterministic', () {
      final counter = TokenCounter.forModel(LlmModel.claude4Sonnet);
      const text = 'Hello, こんにちは, 안녕하세요, 你好!';
      expect(counter.count(text), counter.count(text));
    });

    test('handles emoji without crashing', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      expect(counter.count('Hello 👋🌍'), greaterThan(2));
    });
  });

  group('countMessages', () {
    test('empty array returns 0', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      expect(counter.countMessages([]), 0);
    });

    test('sum includes per-message overhead', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      const content = 'hello';
      final bare = counter.count(content);
      final withEnvelope = counter.countMessages([
        const ChatMessage.user(content),
      ]);
      expect(withEnvelope, greaterThan(bare));
    });

    test('more messages cost more', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final one = counter.countMessages([const ChatMessage.user('hi')]);
      final two = counter.countMessages([
        const ChatMessage.user('hi'),
        const ChatMessage.assistant('hello'),
      ]);
      expect(two, greaterThan(one));
    });

    test('provider overhead differs', () {
      const msgs = [
        ChatMessage.system('be helpful'),
        ChatMessage.user('hi'),
      ];
      final openai = TokenCounter.forModel(LlmModel.gpt4o).countMessages(msgs);
      final google =
          TokenCounter.forModel(LlmModel.gemini2Pro).countMessages(msgs);
      expect(openai, isNot(google));
    });
  });

  group('estimateCost', () {
    test('uses bundled pricing when available', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final cost = counter.estimateCost(
        inputTokens: 1000000,
        outputTokens: 1000000,
      );
      expect(cost, closeTo(12.50, 0.001));
    });

    test('accepts an explicit pricing override', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final cost = counter.estimateCost(
        inputTokens: 1000,
        outputTokens: 500,
        pricing: const ModelPricing(
          inputPerMillion: 1.0,
          outputPerMillion: 2.0,
        ),
      );
      expect(cost, closeTo(0.002, 1e-9));
    });
  });

  group('multilingual coverage', () {
    test('plausible token counts for mixed-script text', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      const sample =
          'English text. 日本語のテキスト。中文文本。한국어 텍스트. '
          'Русский текст. العربية النص. हिंदी पाठ। ภาษาไทย. 😀🎉';
      final tokens = counter.count(sample);
      expect(tokens, greaterThan(20));
      expect(tokens, lessThan(400));
    });
  });
}
