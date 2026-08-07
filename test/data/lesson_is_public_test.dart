import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';

Map<String, dynamic> _lessonJson({bool? isPublic}) => {
  'id': 'l1',
  'title': 'Урок',
  'duration_ms': 1000,
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'version': 1,
  'is_public': ?isPublic,
  'audio': {'id': 'a1'},
  'segments': const <dynamic>[],
};

void main() {
  group('LessonDto.fromJson is_public', () {
    test('читает публичность', () {
      expect(LessonDto.fromJson(_lessonJson(isPublic: false)).isPublic, isFalse);
      expect(LessonDto.fromJson(_lessonJson(isPublic: true)).isPublic, isTrue);
    });

    test('отсутствие поля — публичный урок', () {
      expect(LessonDto.fromJson(_lessonJson()).isPublic, isTrue);
    });

    test('toEntity переносит публичность, isPrivate — обратная', () {
      final lesson = LessonDto.fromJson(
        _lessonJson(isPublic: false),
      ).toEntity(audioPath: '');
      expect(lesson.isPublic, isFalse);
      expect(lesson.isPrivate, isTrue);
    });
  });

  group('LessonModel is_public', () {
    test('переносит is_public из DTO и в сущность', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson(isPublic: false)),
        audioPath: '',
      );
      expect(model.isPublic, isFalse);
      expect(model.toEntity().isPrivate, isTrue);
    });

    test('round-trip через JSON сохраняет is_public', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson(isPublic: false)),
        audioPath: '',
      );
      final restored = LessonModel.fromJson(model.toJson());
      expect(restored.isPublic, isFalse);
    });

    test('JSON без is_public читается как публичный', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson()),
        audioPath: '',
      );
      final json = model.toJson()..remove('is_public');
      expect(LessonModel.fromJson(json).isPublic, isTrue);
    });
  });
}
