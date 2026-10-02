import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/features/lessons/data/datasources/library_remote_datasource.dart';
import 'package:shado/features/lessons/data/repositories/library_repository_impl.dart';
import 'package:shado/features/lessons/domain/repositories/library_repository.dart';
import 'package:shado/features/lessons/domain/usecases/get_library.dart';

/// Dependency wiring for the home feed.
final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>(
  (ref) => ApiLibraryRemoteDataSource(ref.watch(apiClientProvider)),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepositoryImpl(
    remoteDataSource: ref.watch(libraryRemoteDataSourceProvider),
    localDataSource: ref.watch(lessonLocalDataSourceProvider),
  ),
);

final getLibraryProvider = Provider<GetLibrary>(
  (ref) => GetLibrary(ref.watch(libraryRepositoryProvider)),
);
