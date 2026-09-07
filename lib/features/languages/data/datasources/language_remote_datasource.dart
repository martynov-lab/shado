import '../../../../core/network/api_client.dart';
import '../../domain/entities/language.dart';

/// Server-side language directory.
abstract interface class LanguageRemoteDataSource {
  Future<List<Language>> list();
}

class ApiLanguageRemoteDataSource implements LanguageRemoteDataSource {
  const ApiLanguageRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<Language>> list() async {
    final json = await _client.get('/v1/languages');
    // The directory arrives under `languages`, as topics do under `topics`.
    final raw =
        (json['languages'] ?? json['items']) as List<dynamic>? ?? const [];
    return [
      for (final language in raw)
        Language.fromJson(Map<String, dynamic>.from(language as Map)),
    ];
  }
}
