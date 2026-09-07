import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';

import 'lesson_repository_test.dart' show lessonJson;

void main() {
  test('an accent outside the old list arrives as is', () {
    final dto = LessonDto.fromJson(lessonJson(accent: 'AU'));

    expect(dto.accent, 'AU');
    expect(dto.language, 'en');
  });

  test('a language without accents sends accent: null', () {
    final dto = LessonDto.fromJson(lessonJson(language: 'fr', accent: null));

    expect(dto.accent, isNull);
    expect(dto.language, 'fr');
    expect(dto.toEntity(audioPath: '').accent, isNull);
  });

  test('an empty accent counts as unset', () {
    final dto = LessonDto.fromJson(lessonJson(accent: ''));

    expect(dto.accent, isNull);
  });

  test('language and accent survive the cache', () {
    final dto = LessonDto.fromJson(lessonJson(accent: 'AU'));
    final model = LessonModel.fromDto(dto, audioPath: '/tmp/a.mp3');

    expect(model.language, 'en');
    expect(model.accent, 'AU');
    expect(model.toEntity().accent, 'AU');
    expect(model.toEntity().language, 'en');
  });
}
