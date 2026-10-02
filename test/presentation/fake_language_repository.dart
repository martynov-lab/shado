import 'package:shado/features/languages/domain/entities/language.dart';
import 'package:shado/features/languages/domain/repositories/language_repository.dart';

/// A fixed language directory instead of the server.
class FakeLanguageRepository implements LanguageRepository {
  const FakeLanguageRepository(this.languages);

  final List<Language> languages;

  @override
  Future<List<Language>> getLanguages() async => languages;
}
