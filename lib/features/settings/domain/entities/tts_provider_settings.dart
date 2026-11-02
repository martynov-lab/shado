/// AI voice-over provider the server can switch to.
class TtsProviderOption {
  const TtsProviderOption({required this.name, required this.ready});

  factory TtsProviderOption.fromJson(Map<String, dynamic> json) =>
      TtsProviderOption(
        name: json['name'] as String? ?? '',
        ready: json['ready'] as bool? ?? false,
      );

  /// `gemini` or `google`.
  final String name;

  /// Whether the server has the keys for this provider.
  final bool ready;

  /// Label for the UI.
  String get label => switch (name) {
    'gemini' => 'Gemini',
    'google' => 'Google Cloud',
    _ => name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsProviderOption && other.name == name && other.ready == ready;

  @override
  int get hashCode => Object.hash(name, ready);
}

/// The active voice-over provider and the ones available, shared by all users.
class TtsProviderSettings {
  const TtsProviderSettings({required this.active, required this.providers});

  factory TtsProviderSettings.fromJson(Map<String, dynamic> json) =>
      TtsProviderSettings(
        active: json['tts_provider'] as String? ?? '',
        providers: [
          for (final provider
              in (json['tts_providers'] as List<dynamic>? ?? const []))
            TtsProviderOption.fromJson(
              Map<String, dynamic>.from(provider as Map),
            ),
        ],
      );

  /// Name of the provider every synthesis goes to now.
  final String active;

  final List<TtsProviderOption> providers;
}
