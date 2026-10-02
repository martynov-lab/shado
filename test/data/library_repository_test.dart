import 'package:flutter_test/flutter_test.dart';
import 'package:shado/core/error/failures.dart';
import 'package:shado/features/lessons/data/datasources/library_remote_datasource.dart';
import 'package:shado/features/lessons/data/models/folder_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';
import 'package:shado/features/lessons/data/repositories/library_repository_impl.dart';

import 'folder_repository_test.dart' show folderJson;
import 'lesson_repository_test.dart' show FakeLocalDataSource, lessonJson;

class FakeLibraryRemote implements LibraryRemoteDataSource {
  FakeLibraryRemote({this.pages = const []});

  final List<LibraryPage> pages;

  /// Fails every request as if there were no network.
  bool offline = false;

  /// Request cursors in order; they show pages are taken one after another.
  final List<String?> cursors = [];

  int _page = 0;

  @override
  Future<LibraryPage> list({int? limit, String? cursor}) async {
    if (offline) throw const NetworkFailure('offline');
    cursors.add(cursor);
    if (_page >= pages.length) return const LibraryPage();
    return pages[_page++];
  }
}

void main() {
  test('the root splits into folders and unfiled lessons', () async {
    final remote = FakeLibraryRemote(
      pages: [
        LibraryPage(
          folders: [FolderDto.fromJson(folderJson(id: 'f1', lessonCount: 2))],
          lessons: [LessonDto.fromJson(lessonJson(id: 'l1'))],
        ),
      ],
    );
    final repository = LibraryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: FakeLocalDataSource(),
    );

    final root = await repository.getRoot();

    expect(root.folders.map((folder) => folder.id), ['f1']);
    expect(root.folders.single.lessonCount, 2);
    expect(root.lessons.map((lesson) => lesson.id), ['l1']);
    expect(root.isEmpty, isFalse);
  });

  test('pages are walked with one cursor for both halves', () async {
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
    final repository = LibraryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: FakeLocalDataSource(),
    );

    final root = await repository.getRoot();

    expect(remote.cursors, [null, 'c1']);
    expect(root.folders.map((folder) => folder.id), ['f1']);
    expect(root.lessons.map((lesson) => lesson.id), ['l1', 'l2']);
  });

  test('an empty root means an empty library', () async {
    final repository = LibraryRepositoryImpl(
      remoteDataSource: FakeLibraryRemote(),
      localDataSource: FakeLocalDataSource(),
    );

    final root = await repository.getRoot();

    expect(root.isEmpty, isTrue);
  });

  group('offline', () {
    test('the root fetched online is shown offline', () async {
      final local = FakeLocalDataSource();
      local.lessons['l1'] = LessonModel.fromDto(
        LessonDto.fromJson(lessonJson(id: 'l1')),
        audioPath: '',
      );
      final remote = FakeLibraryRemote(
        pages: [
          LibraryPage(
            folders: [FolderDto.fromJson(folderJson(id: 'f1'))],
            lessons: [LessonDto.fromJson(lessonJson(id: 'l1'))],
          ),
        ],
      );
      final repository = LibraryRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
      await repository.getRoot();

      remote.offline = true;
      final root = await repository.getRoot();

      expect(root.folders.map((folder) => folder.id), equals(['f1']));
      expect(root.lessons.map((lesson) => lesson.id), equals(['l1']));
    });

    test('without a saved root the network failure is thrown', () async {
      final repository = LibraryRepositoryImpl(
        remoteDataSource: FakeLibraryRemote()..offline = true,
        localDataSource: FakeLocalDataSource(),
      );

      expect(repository.getRoot(), throwsA(isA<NetworkFailure>()));
    });
  });
}
