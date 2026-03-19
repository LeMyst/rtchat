import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';

class MutedUsersScreen extends StatelessWidget {
  const MutedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mutedUsers),
      ),
      body: Selector<TtsModel, Set<TwitchUserModel>>(
        selector: (_, ttsModel) => ttsModel.mutedUsers,
        shouldRebuild: (prev, next) =>
            prev.length != next.length || !prev.containsAll(next),
        builder: (context, mutedUsersSet, child) {
          final mutedUsers = mutedUsersSet.toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.mutedUsersDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: mutedUsers.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noMutedUsers,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: mutedUsers.length,
                        itemBuilder: (context, index) {
                          final user = mutedUsers[index];
                          return _MutedUserTile(user: user);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MutedUserTile extends StatelessWidget {
  final TwitchUserModel user;

  const _MutedUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName ?? user.login;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.profilePictureUrl.toString()),
      ),
      title: Text(displayName),
      subtitle: Text(user.login),
      trailing: TextButton(
        onPressed: () {
          final ttsModel = Provider.of<TtsModel>(context, listen: false);
          ttsModel.unmute(user);
        },
        child: Text(AppLocalizations.of(context)!.unmute),
      ),
    );
  }
}

