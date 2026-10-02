import '../../../auth/domain/entities/auth_user.dart';

/// What the users screen shows: the loaded page of users and the search.
class AdminUsersState {
  const AdminUsersState({
    this.users = const [],
    this.total = 0,
    this.query = '',
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<AuthUser> users;
  final int total;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;

  AdminUsersState copyWith({
    List<AuthUser>? users,
    int? total,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      total: total ?? this.total,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
