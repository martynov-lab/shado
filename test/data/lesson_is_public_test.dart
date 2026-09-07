import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';

Map<String, dynamic> _lessonJson({bool? isPublic}) => {
  'id': 'l1',
  'title': 'Lesson',
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
    test('reads the visibility', () {
      expect(LessonDto.fromJson(_lessonJson(isPublic: false)).isPublic, isFalse);
      expect(LessonDto.fromJson(_lessonJson(isPublic: true)).isPublic, isTrue);
    });

    test('a missing field means a public lesson', () {
      expect(LessonDto.fromJson(_lessonJson()).isPublic, isTrue);
    });

    test('toEntity carries the visibility over and isPrivate is its inverse', () {
      final lesson = LessonDto.fromJson(
        _lessonJson(isPublic: false),
      ).toEntity(audioPath: '');
      expect(lesson.isPublic, isFalse);
      expect(lesson.isPrivate, isTrue);
    });
  });

  group('LessonModel is_public', () {
    test('carries is_public from the DTO into the entity', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson(isPublic: false)),
        audioPath: '',
      );
      expect(model.isPublic, isFalse);
      expect(model.toEntity().isPrivate, isTrue);
    });

    test('a round-trip through JSON keeps is_public', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson(isPublic: false)),
        audioPath: '',
      );
      final restored = LessonModel.fromJson(model.toJson());
      expect(restored.isPublic, isFalse);
    });

    test('JSON without is_public reads as public', () {
      final model = LessonModel.fromDto(
        LessonDto.fromJson(_lessonJson()),
        audioPath: '',
      );
      final json = model.toJson()..remove('is_public');
      expect(LessonModel.fromJson(json).isPublic, isTrue);
    });
  });
}
