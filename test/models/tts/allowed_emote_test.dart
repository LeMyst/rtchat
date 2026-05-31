import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/tts/allowed_emote.dart';

void main() {
  group('TtsAllowedEmote matching', () {
    test('exact pattern matches only the exact code', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa');
      expect(rule.matches('Kappa'), isTrue);
      expect(rule.matches('KappaPride'), isFalse);
      expect(rule.matches('Kapp'), isFalse);
    });

    test('trailing wildcard matches any suffix', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*');
      expect(rule.matches('Kappa'), isTrue);
      expect(rule.matches('KappaPride'), isTrue);
      expect(rule.matches('KappaHD'), isTrue);
      expect(rule.matches('NotKappa'), isFalse);
    });

    test('leading and embedded wildcards match', () {
      expect(TtsAllowedEmote(pattern: '*Pride').matches('KappaPride'), isTrue);
      expect(TtsAllowedEmote(pattern: 'mo*S').matches('monkaS'), isTrue);
      expect(TtsAllowedEmote(pattern: 'mo*S').matches('monkaW'), isFalse);
    });

    test('lone wildcard matches everything', () {
      final rule = TtsAllowedEmote(pattern: '*');
      expect(rule.matches('Kappa'), isTrue);
      expect(rule.matches('LUL'), isTrue);
      expect(rule.matches(''), isTrue);
    });

    test('question mark matches exactly one character', () {
      final rule = TtsAllowedEmote(pattern: 'LU?');
      expect(rule.matches('LUL'), isTrue);
      expect(rule.matches('LUz'), isTrue);
      expect(rule.matches('LU'), isFalse);
      expect(rule.matches('LULW'), isFalse);
    });

    test('matching is case-sensitive', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*');
      expect(rule.matches('kappa'), isFalse);
    });

    test('regex metacharacters in the pattern are treated literally', () {
      final rule = TtsAllowedEmote(pattern: r':)');
      expect(rule.matches(':)'), isTrue);
      expect(rule.matches('X'), isFalse);
    });
  });

  group('TtsAllowedEmote vocalization', () {
    test('falls back to the emote code without a replacement', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*');
      expect(rule.vocalizationFor('KappaPride'), 'KappaPride');
    });

    test('uses the replacement when configured', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*', replacement: 'Kappa');
      expect(rule.vocalizationFor('KappaPride'), 'Kappa');
    });

    test('treats a blank replacement as none', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*', replacement: '');
      expect(rule.vocalizationFor('KappaPride'), 'KappaPride');
    });
  });

  group('TtsAllowedEmote json', () {
    test('round-trips with a replacement', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*', replacement: 'Kappa');
      final decoded = TtsAllowedEmote.fromJson(rule.toJson());
      expect(decoded, rule);
      expect(decoded.replacement, 'Kappa');
    });

    test('omits a blank replacement from json', () {
      final rule = TtsAllowedEmote(pattern: 'Kappa*', replacement: '');
      expect(rule.toJson().containsKey('replacement'), isFalse);
      final decoded = TtsAllowedEmote.fromJson(rule.toJson());
      expect(decoded.replacement, isNull);
    });
  });
}
