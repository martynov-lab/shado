import 'package:flutter_test/flutter_test.dart';
import 'package:shado/features/lessons/data/models/lesson_dto.dart';
import 'package:shado/features/lessons/data/models/lesson_model.dart';

import 'lesson_repository_test.dart' show lessonJson;

void main() {
  test('акцент вне прежнего списка доезжает как есть', () {
    final dto = LessonDto.fromJson(lessonJson(accent: 'AU'));

    expect(dto.accent, 'AU');
    expect(dto.language, 'en');
  });

  test('язык без акцентов присылает accent: null', () {
    final dto = LessonDto.fromJson(lessonJson(language: 'fr', accent: null));

    expect(dto.accent, isNull);
    expect(dto.language, 'fr');
    expect(dto.toEntity(audioPath: '').accent, isNull);
  });

  test('пустой акцент считается незаполненным', () {
    final dto = LessonDto.fromJson(lessonJson(accent: ''));

    expect(dto.accent, isNull);
  });

  test('язык и акцент переживают кеш', () {
    final dto = LessonDto.fromJson(lessonJson(accent: 'AU'));
    final model = LessonModel.fromDto(dto, audioPath: '/tmp/a.mp3');

    expect(model.language, 'en');
    expect(model.accent, 'AU');
    expect(model.toEntity().accent, 'AU');
    expect(model.toEntity().language, 'en');
  });
}
