import 'dart:async';

import '../../../auth/domain/services/auth_service.dart';
import '../entities/translation_language.dart';
import '../usecases/get_translation_languages.dart';

/// Server default for a profile without a translation language.
const String kDefaultTranslationLanguage = 'ru';

/// The translation language directory and the language picked in the profile.
/// The directory changes only with a server release, so it is loaded once.
class TranslationLanguageService {
  TranslationLanguageService({
    required GetTranslationLanguages getLanguages,
    required AuthService auth,
  }) : _getLanguages = getLanguages,
       _auth = auth {
    _authSubscription = _auth.changes.listen((_) => _emitCurrent());
  }

  final GetTranslationLanguages _getLanguages;
  final AuthService _auth;
  final StreamController<String> _currentChanges =
      StreamController.broadcast();
  late final StreamSubscription<void> _authSubscription;

  List<TranslationLanguage>? _languages;
  Future<List<TranslationLanguage>>? _loading;
  String _lastCode = '';

  /// `null` until the directory is loaded.
  List<TranslationLanguage>? get languages => _languages;

  /// Code of the translation language from the profile.
  String get currentCode =>
      _auth.session.user?.translationLanguage ?? kDefaultTranslationLanguage;

  /// Fires when the profile translation language or the directory changes.
  Stream<String> get currentChanges => _currentChanges.stream;

  /// Loads the directory once and keeps the result, including a failure.
  Future<List<TranslationLanguage>> load() => _loading ??= _fetch();

  /// Saves a new translation language in the profile.
  Future<void> change(String code) =>
      _auth.updateProfile(translationLanguage: code);

  /// Name of the language, or the code itself if it isn't in the directory.
  String labelFor(String code) {
    for (final language in _languages ?? const <TranslationLanguage>[]) {
      if (language.code == code) return language.label;
    }
    return code;
  }

  void dispose() {
    _authSubscription.cancel();
    _currentChanges.close();
  }

  Future<List<TranslationLanguage>> _fetch() async {
    final languages = await _getLanguages();
    _languages = languages;
    _lastCode = '';
    _emitCurrent();
    return languages;
  }

  void _emitCurrent() {
    final code = currentCode;
    if (code == _lastCode) return;
    _lastCode = code;
    _currentChanges.add(code);
  }
}
