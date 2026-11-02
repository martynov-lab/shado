import '../domain/entities/lesson.dart';
import 'screens/lesson/lesson_page.dart';
import 'screens/phrase_set/phrase_set_page.dart';

/// The screen a lesson opens in: the story player or the phrase cards.
String lessonRoute(Lesson lesson) => lesson.isExpressions
    ? PhraseSetPage.routeTo(lesson.id)
    : LessonPage.routeTo(lesson.id);
