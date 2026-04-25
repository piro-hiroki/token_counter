import 'package:test/test.dart';
import 'package:token_counter/token_counter.dart';

void main() {
  group('ImageTokenEstimator.openai', () {
    test('low detail always returns 85', () {
      expect(
        ImageTokenEstimator.openai(
          width: 4096,
          height: 4096,
          detail: ImageDetail.low,
        ),
        85,
      );
    });

    test('small image in high detail → 1 tile = 255', () {
      // 256×256: no scaling needed, 1 tile → 1*170+85 = 255
      expect(
        ImageTokenEstimator.openai(
          width: 256,
          height: 256,
          detail: ImageDetail.high,
        ),
        255,
      );
    });

    test('1024×1024 high detail → 4 tiles = 765', () {
      // Fits in 2048; shortest side 1024 > 768 → scale to 768
      // 768/1024 * 1024 = 768 square → ceil(768/512)=2 tiles each side
      // 2*2*170 + 85 = 765
      expect(
        ImageTokenEstimator.openai(
          width: 1024,
          height: 1024,
          detail: ImageDetail.high,
        ),
        765,
      );
    });

    test('auto: small image (256×256) treated as low detail', () {
      // Both dimensions ≤ 512 → low → 85
      expect(
        ImageTokenEstimator.openai(
          width: 256,
          height: 256,
          detail: ImageDetail.auto,
        ),
        85,
      );
    });

    test('auto: large image (1024×768) treated as high detail', () {
      // Width > 512 → high detail
      expect(
        ImageTokenEstimator.openai(
          width: 1024,
          height: 768,
          detail: ImageDetail.auto,
        ),
        greaterThan(85),
      );
    });
  });

  group('ImageTokenEstimator.claude', () {
    test('1024×1024 → ceil(1024*1024/750) = 1399', () {
      expect(
        ImageTokenEstimator.claude(width: 1024, height: 1024),
        (1024 * 1024 / 750).ceil(),
      );
    });

    test('minimum is 1 token', () {
      expect(ImageTokenEstimator.claude(width: 1, height: 1), 1);
    });
  });

  group('ImageTokenEstimator.gemini', () {
    test('fixed 258 tokens', () {
      expect(ImageTokenEstimator.gemini(), 258);
    });
  });

  group('ToolTokenEstimator', () {
    test('empty list returns 0', () {
      expect(ToolTokenEstimator.estimate(model: LlmModel.gpt4o, tools: []), 0);
    });

    test('non-empty list returns positive token count', () {
      final n = ToolTokenEstimator.estimate(
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
                  'city': {'type': 'string', 'description': 'City name'},
                },
                'required': ['city'],
              },
            },
          },
        ],
      );
      expect(n, greaterThan(5));
    });

    test('more tools → more tokens', () {
      final one = ToolTokenEstimator.estimate(
        model: LlmModel.gpt4o,
        tools: [
          {'name': 'tool_a', 'description': 'Does A'},
        ],
      );
      final two = ToolTokenEstimator.estimate(
        model: LlmModel.gpt4o,
        tools: [
          {'name': 'tool_a', 'description': 'Does A'},
          {'name': 'tool_b', 'description': 'Does B'},
        ],
      );
      expect(two, greaterThan(one));
    });
  });

  group('ChatMessage with images', () {
    test('countMessages adds image tokens for OpenAI', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final withoutImage = counter.countMessages([
        const ChatMessage.user('describe this'),
      ]);
      final withImage = counter.countMessages([
        const ChatMessage.user(
          'describe this',
          images: [ImageAttachment(width: 1024, height: 1024)],
        ),
      ]);
      expect(withImage, greaterThan(withoutImage));
    });

    test('countMessages uses flat token override when provided', () {
      final counter = TokenCounter.forModel(LlmModel.gpt4o);
      final withFlat = counter.countMessages([
        const ChatMessage.user(
          'hi',
          images: [ImageAttachment(flatTokens: 500)],
        ),
      ]);
      final withoutImage = counter.countMessages([
        const ChatMessage.user('hi'),
      ]);
      expect(withFlat - withoutImage, 500);
    });

    test('Gemini charges flat 258 per image', () {
      final counter = TokenCounter.forModel(LlmModel.gemini2Pro);
      final base = counter.countMessages([const ChatMessage.user('hi')]);
      final withImg = counter.countMessages([
        const ChatMessage.user(
          'hi',
          images: [ImageAttachment(width: 512, height: 512)],
        ),
      ]);
      expect(withImg - base, 258);
    });
  });
}
