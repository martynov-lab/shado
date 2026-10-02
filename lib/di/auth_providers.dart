import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shado/di/core_providers.dart';
import 'package:shado/di/lesson_providers.dart';
import 'package:shado/di/progress_providers.dart';
import 'package:shado/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:shado/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:shado/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shado/features/auth/domain/repositories/auth_repository.dart';
import 'package:shado/features/auth/domain/services/auth_service.dart';
import 'package:shado/features/auth/domain/usecases/sign_in.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => ApiAuthRemoteDataSource(ref.watch(apiClientProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => SecureAuthLocalDataSource(),
);

/// Session repository, wired here to cache cleanup and the network layer.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    tokens: ref.watch(tokenStorageProvider),
    // Signing out clears the lesson cache and local progress.
    onSignedOut: () async {
      await ref.read(lessonRepositoryProvider).clearCache();
      await ref.read(progressRepositoryProvider).clear();
    },
  );
  // The interceptor calls this when the server rejects a refresh.
  ref.read(apiClientProvider).onSessionExpired =
      repository.handleSessionExpired;
  ref.onDispose(repository.dispose);
  return repository;
});

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signUpProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final getCurrentUserProvider = Provider<GetCurrentUser>(
  (ref) => GetCurrentUser(ref.watch(authRepositoryProvider)),
);

final updateProfileProvider = Provider<UpdateProfile>(
  (ref) => UpdateProfile(ref.watch(authRepositoryProvider)),
);

/// Starts checking the stored session as soon as it is first read.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService(
    repository: ref.watch(authRepositoryProvider),
    signIn: ref.watch(signInProvider),
    signUp: ref.watch(signUpProvider),
    signOut: ref.watch(signOutProvider),
    getCurrentUser: ref.watch(getCurrentUserProvider),
    updateProfile: ref.watch(updateProfileProvider),
    network: ref.watch(networkMonitorProvider),
  );
  unawaited(service.restore());
  ref.onDispose(service.dispose);
  return service;
});
