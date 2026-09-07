import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/folder_dto.dart';

import 'lesson_repository_test.dart' show lessonJson;

void main() {
  test('the list brings lesson_count only, without lessons', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'TED Talks',
      'is_public': true,
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'version': 2,
      'language': 'en',
      'lesson_count': 3,
    });

    expect(dto.id, 'f1');
    expect(dto.title, 'TED Talks');
    expect(dto.language, 'en');
    expect(dto.lessonCount, 3);
    expect(dto.lessons, isEmpty);
    expect(dto.isDeleted, isFalse);
  });

  test('details bring lessons, each without local audio', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'Course',
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'version': 1,
      'lesson_count': 1,
      'lessons': [lessonJson(id: 'l1', title: 'First')],
    });

    final folder = dto.toEntity();
    expect(folder.lessons, hasLength(1));
    expect(folder.lessons.single.id, 'l1');
    // Lessons in the folder are for opening; the screen fetches the file.
    expect(folder.lessons.single.audioPath, isEmpty);
  });

  test('a non-empty deleted_at marks the folder deleted', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'Old folder',
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'deleted_at': '2026-08-30T11:00:00.000Z',
      'version': 3,
      'lesson_count': 0,
    });

    expect(dto.isDeleted, isTrue);
  });
}
