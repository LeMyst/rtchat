import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/bytes_audio_source.dart';

class TextToSpeechScreen extends StatelessWidget {
  const TextToSpeechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final audioPlayer = AudioPlayer();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.textToSpeech)),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        return ListView(
          children: [
            if (kDebugMode)
              Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Cloud TTS'),
                    value: model.isCloudTtsEnabled,
                    onChanged: (value) {
                      model.isCloudTtsEnabled = value;
                    },
                  ),
                  if (model.isCloudTtsEnabled)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!model.isSupportedLanguage)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.ttsLanguages,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => Navigator.pushNamed(
                                        context,
                                        '/settings/text-to-speech/languages',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            width: 2,
                                            color:
                                                Theme.of(context).dividerColor),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          model.language.displayName(context),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(l10n.ttsVoices,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile.adaptive(
                          title: Text(l10n.ttsPerViewerVoice),
                          subtitle: Text(l10n.ttsPerViewerVoiceSubtitle),
                          value: model.isRandomVoiceEnabled,
                          onChanged: (value) {
                            model.isRandomVoiceEnabled = value;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton(
                                onPressed: model.isRandomVoiceEnabled
                                    ? null
                                    : () {
                                        Navigator.pushNamed(context,
                                            '/settings/text-to-speech/voices');
                                      },
                                style: OutlinedButton.styleFrom(
                                  textStyle:
                                      Theme.of(context).textTheme.titleLarge,
                                  side: BorderSide(
                                      width: 2,
                                      color: Theme.of(context).dividerColor),
                                ).copyWith(
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) =>
                                        states.contains(WidgetState.disabled)
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    model.isRandomVoiceEnabled
                                        ? l10n.ttsRandom
                                        : model.voice,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (model.isCloudTtsEnabled) {
                    final response = await FirebaseFunctions.instance
                        .httpsCallable("synthesize")({
                      "voice": model.voice,
                      "rate": model.speed * 1.5 + 0.5,
                      "pitch": model.pitch * 4 - 2,
                      "text": l10n.sampleMessage,
                    });
                    final bytes = const Base64Decoder().convert(response.data);
                    audioPlayer.setAudioSource(BytesAudioSource(bytes));
                    audioPlayer.play();
                  } else {
                    model.say(
                        l10n,
                        SystemMessageModel(
                          text: l10n.sampleMessage,
                        ),
                        force: true);
                  }
                },
                child: Text(l10n.ttsPlaySampleMessage),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ttsRate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.speed,
                    min: 0.0,
                    max: 1.0,
                    label: "speed: ${model.speed}",
                    onChanged: (value) {
                      model.speed = value;
                    },
                  ),
                  Text(l10n.ttsPitch,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )),
                  Slider.adaptive(
                    value: model.pitch,
                    min: 0.1,
                    max: 2,
                    label: "${model.pitch}",
                    onChanged:
                        model.isRandomVoiceEnabled && model.isCloudTtsEnabled
                            ? null
                            : (value) {
                                model.pitch = value;
                              },
                  ),
                  if (kDebugMode && !model.isCloudTtsEnabled)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/settings/text-to-speech/cloud-tts',
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text: l10n.ttsUnlockHighQualityVoices),
                                  const WidgetSpan(child: SizedBox(width: 8)),
                                  WidgetSpan(
                                    child: Icon(
                                      Icons.lock_open_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsMuteBots),
              value: model.isBotMuted,
              onChanged: (value) {
                model.isBotMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsMuteReplies),
              value: model.isReplyMuted,
              onChanged: (value) {
                model.isReplyMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsMuteEmotes),
              value: model.isEmoteMuted,
              onChanged: (value) {
                model.isEmoteMuted = value;
              },
            ),
            ListTile(
              enabled: model.isEmoteMuted,
              title: Text(l10n.ttsAllowedEmotes),
              subtitle: Text(
                model.isEmoteMuted
                    ? (model.allowedEmotes.isEmpty
                        ? l10n.ttsAllowedEmotesHint
                        : l10n.ttsAllowedEmotesCount(
                            model.allowedEmotes.length))
                    : l10n.ttsAllowedEmotesMuteDisabledHint,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: model.isEmoteMuted
                  ? () => Navigator.pushNamed(
                      context, '/settings/text-to-speech/allowed-emotes')
                  : null,
            ),
            ListTile(
              title: Text(l10n.ttsLimitRepeatedEmojis),
              subtitle: Text(l10n.ttsLimitRepeatedEmojisSubtitle),
              trailing: DropdownButton<int>(
                value: model.maxRepeatedEmojis,
                onChanged: (value) {
                  if (value != null) {
                    model.maxRepeatedEmojis = value;
                  }
                },
                items: [
                  DropdownMenuItem(
                      value: 0, child: Text(l10n.ttsOptionOff)),
                  DropdownMenuItem(
                      value: 1, child: Text(l10n.ttsMaxRepeated(1))),
                  DropdownMenuItem(
                      value: 2, child: Text(l10n.ttsMaxRepeated(2))),
                  DropdownMenuItem(
                      value: 3, child: Text(l10n.ttsMaxRepeated(3))),
                  DropdownMenuItem(
                      value: 5, child: Text(l10n.ttsMaxRepeated(5))),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsMuteViewerNames),
              value: model.isPreludeMuted,
              onChanged: (value) {
                model.isPreludeMuted = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsReplaceUnderscores),
              value: model.isUnderscoreReplacementEnabled,
              onChanged: (value) {
                model.isUnderscoreReplacementEnabled = value;
              },
            ),
            ListTile(
              title: Text(l10n.ttsCollapseRepeatedLetters),
              subtitle: Text(l10n.ttsCollapseRepeatedLettersSubtitle),
              trailing: DropdownButton<int>(
                value: model.maxRepeatedCharactersInNames,
                onChanged: (value) {
                  if (value != null) {
                    model.maxRepeatedCharactersInNames = value;
                  }
                },
                items: [
                  DropdownMenuItem(
                      value: 0, child: Text(l10n.ttsOptionOff)),
                  DropdownMenuItem(
                      value: 1, child: Text(l10n.ttsKeepNLetters(1))),
                  DropdownMenuItem(
                      value: 2, child: Text(l10n.ttsKeepNLetters(2))),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsSimplifyMessages),
              subtitle: Text(l10n.ttsSimplifyMessagesSubtitle),
              value: model.isTextSimplificationEnabled,
              onChanged: (value) {
                model.isTextSimplificationEnabled = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsFloodFilter),
              subtitle: Text(l10n.ttsFloodFilterSubtitle),
              value: model.isFloodFilterEnabled,
              onChanged: (value) {
                model.isFloodFilterEnabled = value;
              },
            ),
            ListTile(
              enabled: model.isFloodFilterEnabled,
              title: Text(l10n.ttsFloodThreshold),
              subtitle: Text(l10n.ttsFloodThresholdSubtitle),
              trailing: DropdownButton<int>(
                value: model.floodFilterThreshold,
                onChanged: model.isFloodFilterEnabled
                    ? (value) {
                        if (value != null) model.floodFilterThreshold = value;
                      }
                    : null,
                items: [
                  DropdownMenuItem(
                      value: 3, child: Text(l10n.ttsNViewers(3))),
                  DropdownMenuItem(
                      value: 5, child: Text(l10n.ttsNViewers(5))),
                  DropdownMenuItem(
                      value: 10, child: Text(l10n.ttsNViewers(10))),
                  DropdownMenuItem(
                      value: 20, child: Text(l10n.ttsNViewers(20))),
                ],
              ),
            ),
            ListTile(
              enabled: model.isFloodFilterEnabled,
              title: Text(l10n.ttsFloodWindow),
              subtitle: Text(l10n.ttsFloodWindowSubtitle),
              trailing: DropdownButton<int>(
                value: model.floodFilterWindowSeconds,
                onChanged: model.isFloodFilterEnabled
                    ? (value) {
                        if (value != null)
                          model.floodFilterWindowSeconds = value;
                      }
                    : null,
                items: [
                  DropdownMenuItem(
                      value: 5, child: Text(l10n.ttsNSeconds(5))),
                  DropdownMenuItem(
                      value: 10, child: Text(l10n.ttsNSeconds(10))),
                  DropdownMenuItem(
                      value: 30, child: Text(l10n.ttsNSeconds(30))),
                  DropdownMenuItem(
                      value: 60, child: Text(l10n.ttsNSeconds(60))),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsGameMode),
              subtitle: Text(l10n.ttsGameModeSubtitle),
              value: model.isGameModeEnabled,
              onChanged: (value) {
                model.isGameModeEnabled = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsSubscribersOnly),
              value: model.isSubscribersOnly,
              onChanged: (value) {
                model.isSubscribersOnly = value;
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.ttsTtsCommandOnly),
              value: model.isTtsCommandEncouraged,
              onChanged: (value) {
                model.isTtsCommandEncouraged = value;
              },
            ),
          ],
        );
      }),
    );
  }
}
