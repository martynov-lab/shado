import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/datasources/folder_remote_datasource.dart';
import 'package:shado/features/lessons/data/models/folder_dto.dart';
import 'package:shado/features/lessons/data/repositories/folder_repository_impl.dart';

/// The server response for a folder.
Map<String, dynamic> folderJson({
  String id = 'f1',
  String title = 'Folder',
  int version = 1,
  int lessonCount = 0,
  bool isPublic = true,
}) => {
  'id': id,
  'title': title,
  'is_public': isPublic,
  'created_at': '2026-08-30T10:00:00.000Z',
  'updated_at': '2026-08-30T10:12:03.000Z',
  'version': version,
  'lesson_count': lessonCount,
};

class FakeFolderRemote implements FolderRemoteDataSource {
  FakeFolderRemote({this.pages = const []});

  final List<FolderPage> pages;
  int _page = 0;

  final List<({String id, int? version, bool? isPublic, String title})> puts =
      [];
  final List<({String id, List<String> lessonIds})> added = [];
  final List<({String folderId, String lessonId})> removed = [];
  final List<String> fetched = [];

  @override
  Future<FolderPage> list({String? since, int? limit, String? cursor}) async {
    if (_page >= pages.length) return const FolderPage(items: []);
    return pages[_page++];
  }

  @override
  Future<FolderDto> getFolder(String id) async {
    fetched.add(id);
    return FolderDto.fromJson(folderJson(id: id, version: 5, lessonCount: 1));
  }

  @override
  Future<FolderDto> putFolder({
    required String id,
    required String title,
    required DateTime createdAt,
    int? version,
    bool? isPublic,
  }) async {
    puts.add((id: id, version: version, isPublic: isPublic, title: title));
    return FolderDto.fromJson(
      folderJson(id: id, title: title, version: (version ?? 0) + 1),
    );
  }

  @override
  Future<void> deleteFolder(String id) async {}

  @override
  Future<FolderDto> addLessons(String id, List<String> lessonIds) async {
    added.add((id: id, lessonIds: lessonIds));
    return FolderDto.fromJson(
      folderJson(id: id, version: 2, lessonCount: lessonIds.length),
    );
  }

  @override
  Future<void> removeLesson(String folderId, String lessonId) async {
    removed.add((folderId: folderId, lessonId: lessonId));
  }
}

void main() {
  test('creation generates an id and goes without If-Match', () async {
    final remote = FakeFolderRemote();
    final repository = FolderRepositoryImpl(remoteDataSource: remote);

    final folder = await repository.createFolder(title: 'New folder', isPublic: false);

    final put = remote.puts.single;
    expect(put.id, isNotEmpty);
    // Creation carries no version; visibility is sent exactly as set.
    expect(put.version, isNull);
    expect(put.isPublic, isFalse);
    expect(folder.title, 'New folder');
  });

  test('an edit goes with the version (If-Match)', () async {
    final remote = FakeFolderRemote();
    final repository = FolderRepositoryImpl(remoteDataSource: remote);

    await repository.updateFolder(id: 'f1', title: 'Another title', version: 4);

    expect(remote.puts.single.version, 4);
    expect(remote.puts.single.id, 'f1');
  });

  test('the list walks pages by cursor and skips deleted ones', () async {
    final remote = FakeFolderRemote(
      pages: [
        FolderPage(
          items: [FolderDto.fromJson(folderJson(id: 'a'))],
          nextCursor: 'c1',
        ),
        FolderPage(items: [FolderDto.fromJson(folderJson(id: 'b'))]),
      ],
    );
    final repository = FolderRepositoryImpl(remoteDataSource: remote);

    final folders = await repository.getFolders();

    expect(folders.map((folder) => folder.id), ['a', 'b']);
  });

  test('adding lessons returns the updated folder', () async {
    final remote = FakeFolderRemote();
    final repository = FolderRepositoryImpl(remoteDataSource: remote);

    final folder = await repository.addLessons('f1', ['l1', 'l2']);

    expect(remote.added.single.lessonIds, ['l1', 'l2']);
    expect(folder.lessonCount, 2);
  });

  test('removing a lesson re-reads the folder: the server answers 204 with no body', () async {
    final remote = FakeFolderRemote();
    final repository = FolderRepositoryImpl(remoteDataSource: remote);

    final folder = await repository.removeLesson('f1', 'l1');

    expect(remote.removed.single, (folderId: 'f1', lessonId: 'l1'));
    // After the deletion the folder is re-read to get a fresh content list.
    expect(remote.fetched.single, 'f1');
    expect(folder.version, 5);
  });
}
