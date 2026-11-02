import '../../../../core/network/api_client.dart';
import '../../domain/entities/translation_language.dart';

/// Server translation endpoints.
abstract interface class TranslationRemoteDataSource {
  Future<List<TranslationLanguage>> languages();

  /// One batch request: up to 200 texts and 10 000 characters.
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  });
}

class ApiTranslationRemoteDataSource implements TranslationRemoteDataSource {
  const ApiTranslationRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<TranslationLanguage>> languages() async {
    final raw = await _client.getList('/v1/translation/languages');
    return [
      for (final language in raw)
        TranslationLanguage.fromJson(
          Map<String, dynamic>.from(language as Map),
        ),
    ];
  }

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required String sourceLang,
  }) async {
    final response = await _client.post(
      '/v1/translate/phrases',
      data: {
        'texts': texts,
        // Without a code the server takes the studied language of the profile.
        if (sourceLang.isNotEmpty) 'source_lang': sourceLang,
      },
    );
    final raw = response.data?['translations'] as List<dynamic>? ?? const [];
    return [for (final text in raw) text as String? ?? ''];
  }
}
