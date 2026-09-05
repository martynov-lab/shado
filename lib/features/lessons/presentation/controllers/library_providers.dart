import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/datasources/library_remote_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/get_library.dart';

/// Dependency wiring for the home feed.
final libraryRemoteDataSourceProvider = Provider<LibraryRemoteDataSource>(
  (ref) => ApiLibraryRemoteDataSource(ref.watch(apiClientProvider)),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => LibraryRepositoryImpl(
    remoteDataSource: ref.watch(libraryRemoteDataSourceProvider),
  ),
);

final getLibraryProvider = Provider<GetLibrary>(
  (ref) => GetLibrary(ref.watch(libraryRepositoryProvider)),
);
