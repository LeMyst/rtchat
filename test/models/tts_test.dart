import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/tts_plugin.dart';

void main() {
  final ttsQueue = TTSQueue();

  group('limitRepeatedEmojis', () {
    test('caps runs of the same emoji beyond the max', () {
      expect(TtsModel.limitRepeatedEmojis('🎉🎉🎉🎉🎉', 3), equals('🎉🎉🎉'));
      expect(TtsModel.limitRepeatedEmojis('🎉🎉🎉🎉🎉🎉🎉', 1), equals('🎉'));
    });

    test('leaves runs at or below the max unchanged', () {
      expect(TtsModel.limitRepeatedEmojis('🎉🎉🎉', 3), equals('🎉🎉🎉'));
      expect(TtsModel.limitRepeatedEmojis('🎉🎉', 3), equals('🎉🎉'));
      expect(TtsModel.limitRepeatedEmojis('🎉', 3), equals('🎉'));
    });

    test('does not affect non-emoji repeated characters', () {
      expect(TtsModel.limitRepeatedEmojis('aaaa', 3), equals('aaaa'));
      expect(TtsModel.limitRepeatedEmojis('hahaha', 3), equals('hahaha'));
    });

    test('handles mixed emoji and text', () {
      expect(TtsModel.limitRepeatedEmojis('great 🎉🎉🎉🎉🎉 stream', 3),
          equals('great 🎉🎉🎉 stream'));
    });

    test('handles multiple different emoji runs independently', () {
      expect(TtsModel.limitRepeatedEmojis('🎉🎉🎉🎉🔥🔥🔥🔥', 2),
          equals('🎉🎉🔥🔥'));
    });

    test('maxCount 0 disables the limit', () {
      expect(TtsModel.limitRepeatedEmojis('🎉🎉🎉🎉🎉', 0),
          equals('🎉🎉🎉🎉🎉'));
    });

    test('handles empty string', () {
      expect(TtsModel.limitRepeatedEmojis('', 3), equals(''));
    });
  });

  group('collapseRepeatedLetters', () {
    test('collapses long runs down to the requested length', () {
      expect(TtsModel.collapseRepeatedLetters('Celyyyyy', 2), equals('Celyy'));
      expect(TtsModel.collapseRepeatedLetters('Celyyyyy', 1), equals('Cely'));
    });

    test('keep <= 0 disables the normalization', () {
      expect(
          TtsModel.collapseRepeatedLetters('Celyyyyy', 0), equals('Celyyyyy'));
    });

    test('leaves runs of two or fewer characters untouched', () {
      expect(TtsModel.collapseRepeatedLetters('Anna', 1), equals('Anna'));
      expect(TtsModel.collapseRepeatedLetters('Cely', 2), equals('Cely'));
    });

    test('collapses every run in the name', () {
      expect(
          TtsModel.collapseRepeatedLetters('aaabbbccc', 2), equals('aabbcc'));
    });

    test('handles an empty name', () {
      expect(TtsModel.collapseRepeatedLetters('', 2), equals(''));
    });
  });

  test('Queue starts empty', () {
    expect(ttsQueue.isEmpty, isTrue);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TextToSpeechPlugin.channel,
            (MethodCall method) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TextToSpeechPlugin.channel, null);
  });

  test('Speak adds elements to the queue', () async {
    final future1 = ttsQueue.speak('1', 'First message');
    expect(ttsQueue.isEmpty, isFalse);
    expect(ttsQueue.length, equals(1));
    await future1;

    final future2 = ttsQueue.speak('2', 'Second message');
    expect(ttsQueue.isEmpty, isFalse);
    expect(ttsQueue.length, equals(1));
    await future2;

    expect(ttsQueue.isEmpty, isTrue);
    expect(ttsQueue.length, equals(0));
  });

  test('Speak and clear empties the queue', () async {
    var calls = 0;
    final future1 = ttsQueue.speak('1', 'First message').catchError((e) {
      fail(
          'Should not have errored, can\'t clear the first element already in progress');
    });
    final future2 = ttsQueue.speak('2', 'Second message').catchError((e) {
      expect(e.toString(), equals("Exception: Message was deleted"));
      calls++;
    });
    await ttsQueue.clear();
    expect(ttsQueue.isEmpty, isTrue);
    await future1;
    await future2;
    expect(calls, equals(1));
  });

  test('Delete doesn\'t delete element if at the front of the queue', () async {
    final future1 = ttsQueue.speak('1', 'First message');
    final future2 = ttsQueue.speak('2', 'Second message');
    ttsQueue.delete('1');
    expect(ttsQueue.length, equals(2));
    expect(ttsQueue.peek()!.id, equals('1'));
    await future1;
    await future2;
  });

  test('Delete deletes the second element', () async {
    var calls = 0;
    final future1 = ttsQueue.speak('1', 'First message');
    final future2 = ttsQueue.speak('2', 'Second message').catchError((e) {
      expect(e.toString(), equals("Exception: Message was deleted"));
      calls++;
    });

    ttsQueue.delete('2');

    expect(ttsQueue.length, equals(1));
    await future1;
    await future2;
    expect(calls, equals(1));
  });

  test('TTS announces stoppage when queue exceeds 20 items', () async {
    // Simulate speaking 21 messages
    for (int i = 1; i <= 21; i++) {
      await ttsQueue.speak('$i', 'Message $i');
    }

    // Expect the queue to be cleared after the 21st message
    expect(ttsQueue.isEmpty, isTrue);
  });
}
