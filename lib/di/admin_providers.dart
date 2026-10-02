import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/features/admin/data/admin_remote_datasource.dart';
import 'package:shado/features/admin/data/repositories/admin_users_repository_impl.dart';
import 'package:shado/features/admin/domain/repositories/admin_users_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => ApiAdminRemoteDataSource(ref.watch(apiClientProvider)),
);

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);
