import 'dart:async';

import '../../../auth/domain/services/auth_service.dart';
import '../entities/language.dart';
import '../usecases/get_languages.dart';

/// The language directory and the language the user studies. The directory
/// changes only with a server release, so it is loaded once per session.
class LanguageService {
  LanguageService({
    required GetLanguages getLanguages,
    required AuthService auth,
  }) : _getLanguages = getLanguages,
       _auth = auth {
    _authSubscription = _auth.changes.listen((_) => _emitCurrent());
  }

  final GetLanguages _getLanguages;
  final AuthService _auth;
  final StreamController<List<Language>> _changes =
      StreamController.broadcast();
  final StreamController<Language?> _currentChanges =
      StreamController.broadcast();
  late final StreamSubscription<void> _authSubscription;

  List<Language>? _languages;
  Future<List<Language>>? _loading;

  /// `null` until the directory is loaded.
  List<Language>? get languages => _languages;

  Stream<List<Language>> get changes => _changes.stream;

  /// Code of the studied language from the profile; may be missing from the
  /// directory.
  String? get currentCode => _auth.session.user?.studiedLanguage;

  /// `null` while the directory loads or when the code is not in it.
  Language? get current {
    final code = currentCode;
    if (code == null || code.isEmpty) return null;
    for (final language in _languages ?? const <Language>[]) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// Empty for a language without accents and while the directory loads.
  List<Accent> get currentAccents => current?.accents ?? const [];

  /// Fires when the profile language or the directory changes.
  Stream<Language?> get currentChanges => _currentChanges.stream;

  /// Loads the directory once and keeps the result, including a failure.
  Future<List<Language>> load() => _loading ??= _fetch();

  /// Loads the directory only when the profile has a studied language:
  /// without one there is nothing to match it against.
  void loadForCurrent() {
    final code = currentCode;
    if (code != null && code.isNotEmpty) load().ignore();
  }

  /// Name of the language, or the code itself if it isn't in the directory.
  String labelFor(String code) {
    for (final language in _languages ?? const <Language>[]) {
      if (language.code == code) return language.label;
    }
    return code;
  }

  void dispose() {
    _authSubscription.cancel();
    _changes.close();
    _currentChanges.close();
  }

  Future<List<Language>> _fetch() async {
    final languages = await _getLanguages();
    _languages = languages;
    _changes.add(languages);
    _emitCurrent();
    return languages;
  }

  void _emitCurrent() => _currentChanges.add(current);
}
