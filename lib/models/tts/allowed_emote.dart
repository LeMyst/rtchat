/// A user-configured rule describing an emote that should still be read aloud
/// by text to speech even when "mute all emotes" is enabled.
///
/// [pattern] supports two wildcards:
///   * `*` matches any (possibly empty) sequence of characters.
///   * `?` matches exactly one character.
/// For example `Kappa*` matches `Kappa`, `KappaPride`, `KappaHD`, etc.
///
/// When [replacement] is set, that text is spoken instead of the matched emote
/// code. This lets a viewer allow `Kappa*` but have every variant simply read
/// as `Kappa`. When it's null or empty the original emote code is spoken.
class TtsAllowedEmote {
  final String pattern;
  final String? replacement;
  final RegExp _matcher;

  TtsAllowedEmote({required this.pattern, this.replacement})
      : _matcher = _compile(pattern);

  /// Whether the given emote [code] is covered by this rule.
  bool matches(String code) => _matcher.hasMatch(code);

  /// The text that should be spoken for [code] under this rule.
  String vocalizationFor(String code) {
    final replacement = this.replacement;
    if (replacement == null || replacement.isEmpty) {
      return code;
    }
    return replacement;
  }

  /// Compiles a wildcard [pattern] into an anchored, case-sensitive [RegExp].
  /// Emote codes are case-sensitive on Twitch, so matching is too.
  static RegExp _compile(String pattern) {
    final buffer = StringBuffer('^');
    for (final char in pattern.split('')) {
      switch (char) {
        case '*':
          buffer.write('.*');
          break;
        case '?':
          buffer.write('.');
          break;
        default:
          // Escape anything the regex engine would otherwise interpret.
          if (r'\^$.|+()[]{}'.contains(char)) {
            buffer.write('\\');
          }
          buffer.write(char);
      }
    }
    buffer.write(r'$');
    return RegExp(buffer.toString());
  }

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        if (replacement != null && replacement!.isNotEmpty)
          'replacement': replacement,
      };

  factory TtsAllowedEmote.fromJson(Map<String, dynamic> json) =>
      TtsAllowedEmote(
        pattern: json['pattern'] as String,
        replacement: json['replacement'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is TtsAllowedEmote &&
      other.pattern == pattern &&
      other.replacement == replacement;

  @override
  int get hashCode => Object.hash(pattern, replacement);

  @override
  String toString() => replacement == null || replacement!.isEmpty
      ? pattern
      : '$pattern -> $replacement';
}
