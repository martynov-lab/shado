import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/folder_dto.dart';

import 'lesson_repository_test.dart' show lessonJson;

void main() {
  test('в списке приходит только lesson_count, без уроков', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'TED-разговорный',
      'is_public': true,
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'version': 2,
      'lesson_count': 3,
    });

    expect(dto.id, 'f1');
    expect(dto.title, 'TED-разговорный');
    expect(dto.lessonCount, 3);
    expect(dto.lessons, isEmpty);
    expect(dto.isDeleted, isFalse);
  });

  test('детали приносят уроки, каждый — без локального аудио', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'Курс',
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'version': 1,
      'lesson_count': 1,
      'lessons': [lessonJson(id: 'l1', title: 'Первый')],
    });

    final folder = dto.toEntity();
    expect(folder.lessons, hasLength(1));
    expect(folder.lessons.single.id, 'l1');
    // Lessons in the folder are for opening; the screen fetches the file.
    expect(folder.lessons.single.audioPath, isEmpty);
  });

  test('непустой deleted_at помечает папку удалённой', () {
    final dto = FolderDto.fromJson({
      'id': 'f1',
      'title': 'Старая',
      'created_at': '2026-08-30T10:00:00.000Z',
      'updated_at': '2026-08-30T10:12:03.000Z',
      'deleted_at': '2026-08-30T11:00:00.000Z',
      'version': 3,
      'lesson_count': 0,
    });

    expect(dto.isDeleted, isTrue);
  });
}
