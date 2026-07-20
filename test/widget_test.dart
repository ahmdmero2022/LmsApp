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

    test('completedAt round-trips and defaults to null', () {
      final base = Enrollment(studentId: 's1', courseId: 'c1');
      expect(base.completedAt, isNull);
      expect(Enrollment.fromMap(base.toMap()).completedAt, isNull);

      final when = DateTime(2026, 7, 18, 12, 30);
      final done = base.copyWith(completedAt: when);
      final restored = Enrollment.fromMap(done.toMap());
      expect(restored.completedAt, when);
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

  group('Lesson editing', () {
    Course courseWithLessons() => Course(
          title: 'C',
          description: 'D',
          category: 'Cat',
          instructorId: 'i1',
          instructorName: 'T',
          colorValue: 0xFF1565C0,
          lessons: [
            Lesson(id: 'l1', title: 'First', durationMinutes: 5),
            Lesson(id: 'l2', title: 'Second', durationMinutes: 5),
          ],
        );

    test('copyWith replaces a lesson by id, preserving order', () {
      final course = courseWithLessons();
      final edited = course.lessons[0].copyWith(title: 'First edited');
      final updated = course.copyWith(
        lessons: [
          for (final l in course.lessons) if (l.id == edited.id) edited else l,
        ],
      );
      expect(updated.lessons.length, 2);
      expect(updated.lessons[0].id, 'l1');
      expect(updated.lessons[0].title, 'First edited');
      expect(updated.lessons[1].title, 'Second');
    });

    test('copyWith removes a lesson by id', () {
      final course = courseWithLessons();
      final updated = course.copyWith(
        lessons: course.lessons.where((l) => l.id != 'l1').toList(),
      );
      expect(updated.lessons.length, 1);
      expect(updated.lessons.single.id, 'l2');
    });

    test('deleting a lesson drops it from an enrollment progress set', () {
      final enrollment = Enrollment(
        studentId: 's1',
        courseId: 'c1',
        completedLessonIds: ['l1', 'l2'],
      );
      final pruned = enrollment.copyWith(
        completedLessonIds:
            enrollment.completedLessonIds.where((id) => id != 'l1').toList(),
      );
      expect(pruned.completedLessonIds, ['l2']);
      expect(pruned.progress(1), 1);
    });
  });

  group('Quiz question editing', () {
    Course courseWithQuiz() => Course(
          title: 'C',
          description: 'D',
          category: 'Cat',
          instructorId: 'i1',
          instructorName: 'T',
          colorValue: 0xFF1565C0,
          quiz: [
            QuizQuestion(
              id: 'q1',
              prompt: 'Old prompt',
              options: ['A', 'B'],
              correctIndex: 0,
            ),
            QuizQuestion(
              id: 'q2',
              prompt: 'Keep',
              options: ['X', 'Y'],
              correctIndex: 1,
            ),
          ],
        );

    test('copyWith replaces a question by id', () {
      final course = courseWithQuiz();
      final edited = course.quiz[0]
          .copyWith(prompt: 'New prompt', correctIndex: 1);
      final updated = course.copyWith(
        quiz: [
          for (final q in course.quiz) if (q.id == edited.id) edited else q,
        ],
      );
      expect(updated.quiz.length, 2);
      expect(updated.quiz[0].id, 'q1');
      expect(updated.quiz[0].prompt, 'New prompt');
      expect(updated.quiz[0].correctIndex, 1);
      expect(updated.quiz[1].prompt, 'Keep');
    });

    test('copyWith removes a question by id', () {
      final course = courseWithQuiz();
      final updated = course.copyWith(
        quiz: course.quiz.where((q) => q.id != 'q1').toList(),
      );
      expect(updated.quiz.length, 1);
      expect(updated.quiz.single.id, 'q2');
    });
  });
}
