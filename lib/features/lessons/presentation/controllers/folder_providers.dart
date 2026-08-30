import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/datasources/folder_remote_datasource.dart';
import '../../data/repositories/folder_repository_impl.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/usecases/add_lessons_to_folder.dart';
import '../../domain/usecases/create_folder.dart';
import '../../domain/usecases/delete_folder.dart';
import '../../domain/usecases/get_folder.dart';
import '../../domain/usecases/get_folders.dart';
import '../../domain/usecases/remove_lesson_from_folder.dart';
import '../../domain/usecases/update_folder.dart';

/// Сборка зависимостей папок. Presentation дальше видит только use case'ы.
final folderRemoteDataSourceProvider = Provider<FolderRemoteDataSource>(
  (ref) => ApiFolderRemoteDataSource(ref.watch(apiClientProvider)),
);

final folderRepositoryProvider = Provider<FolderRepository>(
  (ref) => FolderRepositoryImpl(
    remoteDataSource: ref.watch(folderRemoteDataSourceProvider),
  ),
);

final getFoldersProvider = Provider<GetFolders>(
  (ref) => GetFolders(ref.watch(folderRepositoryProvider)),
);

final getFolderProvider = Provider<GetFolder>(
  (ref) => GetFolder(ref.watch(folderRepositoryProvider)),
);

final createFolderProvider = Provider<CreateFolder>(
  (ref) => CreateFolder(ref.watch(folderRepositoryProvider)),
);

final updateFolderProvider = Provider<UpdateFolder>(
  (ref) => UpdateFolder(ref.watch(folderRepositoryProvider)),
);

final deleteFolderProvider = Provider<DeleteFolder>(
  (ref) => DeleteFolder(ref.watch(folderRepositoryProvider)),
);

final addLessonsToFolderProvider = Provider<AddLessonsToFolder>(
  (ref) => AddLessonsToFolder(ref.watch(folderRepositoryProvider)),
);

final removeLessonFromFolderProvider = Provider<RemoveLessonFromFolder>(
  (ref) => RemoveLessonFromFolder(ref.watch(folderRepositoryProvider)),
);
