import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../lessons/presentation/controllers/lesson_providers.dart';
import '../../../lessons/presentation/controllers/lessons_controller.dart';
import '../../../lessons/presentation/controllers/lessons_filter.dart';
import '../../../lessons/presentation/controllers/library_controller.dart';

/// Studied language switch; the state is a saving flag.
class StudiedLanguageController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Switches the studied language and reloads the catalog; `null` means
  /// success. The order matters: the old catalog must not land on the new one.
  Future<String?> change(String code) async {
    if (state) return null;
    state = true;
    try {
      // 1. Wait for the profile to accept the language.
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(studiedLanguage: code);
      // 2. Drop the cached lessons, the watermark and the downloaded audio.
      await ref.read(lessonRepositoryProvider).clearCache();
      // 3. Drop the filters: the server rejects an accent of another language.
      ref.read(lessonsFilterProvider.notifier).reset();
      // 4. Reload the catalog and the folder feed from scratch.
      ref.invalidate(lessonsControllerProvider);
      ref.invalidate(libraryControllerProvider);
      return null;
    } on ApiException catch (error) {
      // The server does not know the code — the previous language stays.
      return error.status == 422
          ? 'Сервер не принял язык — выберите другой'
          : error.message;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return 'Не удалось сменить язык: $error';
    } finally {
      state = false;
    }
  }
}

/// `true` while the studied language is being switched.
final studiedLanguageControllerProvider =
    NotifierProvider<StudiedLanguageController, bool>(
      StudiedLanguageController.new,
    );
