import 'package:test/test.dart';
import 'package:token_counter/token_counter.dart';

void main() {
  group('LlmModel context window', () {
    test('gpt4o has 128k context window', () {
      expect(LlmModel.gpt4o.contextWindow, 128000);
    });

    test('gemini15Pro has 2M context window', () {
      expect(LlmModel.gemini15Pro.contextWindow, 2097152);
    });

    test('all models have positive context window and maxOutputTokens', () {
      for (final model in LlmModel.values) {
        expect(model.contextWindow, greaterThan(0),
            reason: '${model.name} contextWindow should be > 0');
        expect(model.maxOutputTokens, greaterThan(0),
            reason: '${model.name} maxOutputTokens should be > 0');
      }
    });
  });

  group('TokenCounter.fitsInContext', () {
    test('short text fits', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      expect(counter.fitsInContext('Hello'), isTrue);
    });

    test('very long text does not fit in small context', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4);
      // gpt4 has 8192 token window; 40k chars of English ≈ 10k tokens
      final longText = 'word ' * 40000;
      expect(counter.fitsInContext(longText), isFalse);
    });
  });

  group('TokenCounter.remainingContextTokens', () {
    test('short text leaves most context free', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final remaining = counter.remainingContextTokens('Hello');
      expect(remaining, greaterThan(127000));
    });

    test('reserveForOutput reduces remaining', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final without = counter.remainingContextTokens('Hello');
      final withReserve =
          counter.remainingContextTokens('Hello', reserveForOutput: 1000);
      expect(without - withReserve, 1000);
    });

    test('returns negative when text exceeds context', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4);
      final longText = 'word ' * 40000;
      expect(counter.remainingContextTokens(longText), isNegative);
    });
  });

  group('TokenCounter.truncate', () {
    test('short text returned unchanged', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      const text = 'Hello world';
      expect(counter.truncate(text, 100), text);
    });

    test('truncated result fits within maxTokens', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final text = 'word ' * 1000;
      const maxTokens = 50;
      final truncated = counter.truncate(text, maxTokens);
      expect(counter.count(truncated), lessThanOrEqualTo(maxTokens));
    });

    test('maxTokens = 0 returns empty string', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      expect(counter.truncate('hello world', 0), '');
    });

    test('truncated result is non-empty for positive maxTokens', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final truncated = counter.truncate('hello world foo bar', 2);
      expect(truncated.isNotEmpty, isTrue);
    });
  });
}
