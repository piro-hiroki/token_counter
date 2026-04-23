import 'package:test/test.dart';
import 'package:token_counter/src/script_classifier.dart';

void main() {
  group('classifyCodeUnit', () {
    test('classifies ASCII letters', () {
      expect(classifyCodeUnit('a'.codeUnitAt(0)), ScriptBucket.latin);
      expect(classifyCodeUnit('Z'.codeUnitAt(0)), ScriptBucket.latin);
    });

    test('classifies digits', () {
      expect(classifyCodeUnit('0'.codeUnitAt(0)), ScriptBucket.digit);
      expect(classifyCodeUnit('9'.codeUnitAt(0)), ScriptBucket.digit);
    });

    test('classifies whitespace', () {
      expect(classifyCodeUnit(' '.codeUnitAt(0)), ScriptBucket.whitespace);
      expect(classifyCodeUnit('\n'.codeUnitAt(0)), ScriptBucket.whitespace);
    });

    test('classifies CJK ideographs', () {
      expect(classifyCodeUnit('漢'.runes.first), ScriptBucket.cjkIdeograph);
      expect(classifyCodeUnit('中'.runes.first), ScriptBucket.cjkIdeograph);
    });

    test('classifies kana', () {
      expect(classifyCodeUnit('あ'.runes.first), ScriptBucket.hiragana);
      expect(classifyCodeUnit('カ'.runes.first), ScriptBucket.katakana);
    });

    test('classifies Hangul', () {
      expect(classifyCodeUnit('한'.runes.first), ScriptBucket.hangul);
    });

    test('classifies emoji in supplementary plane', () {
      expect(classifyCodeUnit('😀'.runes.first), ScriptBucket.emoji);
    });

    test('unknown / private-use falls back to other', () {
      expect(classifyCodeUnit(0xE000), ScriptBucket.other);
    });
  });
}
