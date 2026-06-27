import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/allowed_emote.dart';

class AllowedEmotesScreen extends StatelessWidget {
  const AllowedEmotesScreen({super.key});

  Future<void> _showEditor(BuildContext context,
      {TtsAllowedEmote? existing, int? index}) async {
    final model = Provider.of<TtsModel>(context, listen: false);
    final result = await showDialog<TtsAllowedEmote>(
      context: context,
      builder: (context) => _AllowedEmoteDialog(existing: existing),
    );
    if (result == null) {
      return;
    }
    if (index != null) {
      model.updateAllowedEmote(index, result);
    } else {
      model.addAllowedEmote(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.ttsAllowedEmotesScreenTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<TtsModel>(builder: (context, model, child) {
        final emotes = model.allowedEmotes;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.ttsAllowedEmotesDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: emotes.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.ttsNoAllowedEmotes,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: emotes.length,
                      itemBuilder: (context, index) {
                        final emote = emotes[index];
                        final replacement = emote.replacement;
                        return ListTile(
                          title: Text(emote.pattern),
                          subtitle:
                              replacement != null && replacement.isNotEmpty
                                  ? Text(AppLocalizations.of(context)!.ttsAllowedEmoteSpokenAs(replacement))
                                  : null,
                          onTap: () => _showEditor(context,
                              existing: emote, index: index),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: AppLocalizations.of(context)!.remove,
                            onPressed: () => model.removeAllowedEmoteAt(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _AllowedEmoteDialog extends StatefulWidget {
  final TtsAllowedEmote? existing;

  const _AllowedEmoteDialog({this.existing});

  @override
  State<_AllowedEmoteDialog> createState() => _AllowedEmoteDialogState();
}

class _AllowedEmoteDialogState extends State<_AllowedEmoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _patternController;
  late final TextEditingController _replacementController;

  @override
  void initState() {
    super.initState();
    _patternController =
        TextEditingController(text: widget.existing?.pattern ?? '');
    _replacementController =
        TextEditingController(text: widget.existing?.replacement ?? '');
  }

  @override
  void dispose() {
    _patternController.dispose();
    _replacementController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final replacement = _replacementController.text.trim();
    Navigator.of(context).pop(TtsAllowedEmote(
      pattern: _patternController.text.trim(),
      replacement: replacement.isEmpty ? null : replacement,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.ttsAddEmote : l10n.ttsEditEmote),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _patternController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.ttsEmotePattern,
                hintText: l10n.ttsEmotePatternHint,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.ttsEmotePatternRequired
                  : null,
            ),
            TextFormField(
              controller: _replacementController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.ttsEmoteReplacement,
                hintText: l10n.ttsEmoteReplacementHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
