import 'package:flutter_test/flutter_test.dart';

import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/enrollment.dart';
import 'package:lms_app/models/lesson.dart';
import 'package:lms_app/models/quiz.dart';

void main() {
  group('Enrollment progress', () {
    test('is zero with no completed lessons', () {
      final enrollment =
          Enrollment(studentId: 's1', courseId: 'c1');
      expect(enrollment.progress(4), 0);
      expect(enrollment.isCompleted(4), isFalse);
    });

    test('tracks partial and full completion', () {
      final enrollment = Enrollment(
        studentId: 's1',
        courseId: 'c1',
        completedLessonIds: ['l1', 'l2'],
      );
      expect(enrollment.progress(4), 0.5);
      expect(enrollment.isCompleted(2), isTrue);
    });
  });

  group('Course serialization', () {
    test('round-trips through a map', () {
      final course = Course(
        title: 'Test',
        description: 'Desc',
        category: 'Cat',
        instructorId: 'i1',
        instructorName: 'Teacher',
        colorValue: 0xFF1565C0,
        lessons: [Lesson(title: 'L1', content: 'c', durationMinutes: 5)],
      );
      final restored = Course.fromMap(course.toMap());
      expect(restored.title, course.title);
      expect(restored.lessons.length, 1);
      expect(restored.totalMinutes, 5);
    });

    test('round-trips media lessons and a quiz', () {
      final course = Course(
        title: 'Media',
        description: 'Desc',
        category: 'Cat',
        instructorId: 'i1',
        instructorName: 'Teacher',
        colorValue: 0xFF1565C0,
        lessons: [
          Lesson(
            title: 'Intro video',
            type: LessonType.video,
            url: 'https://youtu.be/abc',
            durationMinutes: 4,
          ),
          Lesson(
            title: 'Notes',
            type: LessonType.pdf,
            url: 'https://example.com/a.pdf',
          ),
        ],
        quiz: [
          QuizQuestion(
            prompt: 'Pick A',
            options: ['A', 'B'],
            correctIndex: 0,
          ),
        ],
      );
      final restored = Course.fromMap(course.toMap());
      expect(restored.lessons[0].type, LessonType.video);
      expect(restored.lessons[0].url, 'https://youtu.be/abc');
      expect(restored.lessons[1].type, LessonType.pdf);
      expect(restored.hasQuiz, isTrue);
      expect(restored.quiz.single.prompt, 'Pick A');
      expect(restored.quiz.single.isCorrect(0), isTrue);
      expect(restored.quiz.single.isCorrect(1), isFalse);
    });
  });

  group('Quiz scoring', () {
    test('enrollment stores best quiz score', () {
      final e = Enrollment(studentId: 's1', courseId: 'c1');
      expect(e.quizAttempted, isFalse);
      final scored = e.copyWith(quizScore: 80);
      expect(scored.quizAttempted, isTrue);
      expect(scored.quizScore, 80);
      final restored = Enrollment.fromMap(scored.toMap());
      expect(restored.quizScore, 80);
    });
  });
}
