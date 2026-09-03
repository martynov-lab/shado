import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/datasources/library_remote_datasource.dart';
import 'package:shado/features/lessons/data/models/folder_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/repositories/library_repository_impl.dart';

import 'folder_repository_test.dart' show folderJson;
import 'lesson_repository_test.dart' show lessonJson;

class FakeLibraryRemote implements LibraryRemoteDataSource {
  FakeLibraryRemote({this.pages = const []});

  final List<LibraryPage> pages;

  /// Курсоры запросов по порядку — по ним видно, что страницы берутся подряд.
  final List<String?> cursors = [];

  int _page = 0;

  @override
  Future<LibraryPage> list({int? limit, String? cursor}) async {
    cursors.add(cursor);
    if (_page >= pages.length) return const LibraryPage();
    return pages[_page++];
  }
}

void main() {
  test('корень разбирается на папки и свободные уроки', () async {
    final remote = FakeLibraryRemote(
      pages: [
        LibraryPage(
          folders: [FolderDto.fromJson(folderJson(id: 'f1', lessonCount: 2))],
          lessons: [LessonDto.fromJson(lessonJson(id: 'l1'))],
        ),
      ],
    );
    final repository = LibraryRepositoryImpl(remoteDataSource: remote);

    final root = await repository.getRoot();

    expect(root.folders.map((folder) => folder.id), ['f1']);
    expect(root.folders.single.lessonCount, 2);
    expect(root.lessons.map((lesson) => lesson.id), ['l1']);
    expect(root.isEmpty, isFalse);
  });

  test('страницы обходятся одним курсором на обе половины', () async {
    final remote = FakeLibraryRemote(
      pages: [
        LibraryPage(
          folders: [FolderDto.fromJson(folderJson(id: 'f1'))],
          lessons: [LessonDto.fromJson(lessonJson(id: 'l1'))],
          nextCursor: 'c1',
        ),
        LibraryPage(lessons: [LessonDto.fromJson(lessonJson(id: 'l2'))]),
      ],
    );
    final repository = LibraryRepositoryImpl(remoteDataSource: remote);

    final root = await repository.getRoot();

    expect(remote.cursors, [null, 'c1']);
    expect(root.folders.map((folder) => folder.id), ['f1']);
    expect(root.lessons.map((lesson) => lesson.id), ['l1', 'l2']);
  });

  test('пустой корень — библиотека пуста', () async {
    final repository = LibraryRepositoryImpl(
      remoteDataSource: FakeLibraryRemote(),
    );

    final root = await repository.getRoot();

    expect(root.isEmpty, isTrue);
  });
}
