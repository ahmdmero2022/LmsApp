import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/models/analytics.dart';
import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/enrollment.dart';
import 'package:lms_app/models/lesson.dart';
import 'package:lms_app/models/review.dart';

Lesson _lesson(String id) =>
    Lesson(id: id, title: id, type: LessonType.text, content: 'x');

Course _course(String id, {int lessons = 2}) => Course(
      id: id,
      title: 'Course $id',
      description: '',
      category: 'General',
      instructorId: 'inst',
      instructorName: 'Inst',
      colorValue: 0xFF000000,
      lessons: [for (var i = 0; i < lessons; i++) _lesson('$id-l$i')],
    );

void main() {
  group('computeCourseStats', () {
    final course = _course('c1', lessons: 2);
    final lessonIds = course.lessons.map((l) => l.id).toList();

    test('empty enrollments yield zeroed stats and null averages', () {
      final s = computeCourseStats(course, [], []);
      expect(s.enrollments, 0);
      expect(s.completions, 0);
      expect(s.completionRate, 0);
      expect(s.avgProgress, 0);
      expect(s.avgQuizScore, isNull);
      expect(s.quizAttempts, 0);
      expect(s.avgRating, isNull);
      expect(s.reviewCount, 0);
    });

    test('counts completions, progress, quiz average and ratings', () {
      final enrollments = [
        // fully complete + quiz 80
        Enrollment(
          studentId: 's1',
          courseId: 'c1',
          completedLessonIds: lessonIds,
          quizScore: 80,
        ),
        // half complete + quiz 60
        Enrollment(
          studentId: 's2',
          courseId: 'c1',
          completedLessonIds: [lessonIds.first],
          quizScore: 60,
        ),
        // not started, no quiz
        Enrollment(studentId: 's3', courseId: 'c1'),
        // different course, should be ignored
        Enrollment(
          studentId: 's4',
          courseId: 'other',
          completedLessonIds: const ['x'],
          quizScore: 10,
        ),
      ];
      final reviews = [
        Review(courseId: 'c1', studentId: 's1', studentName: 'A', rating: 5),
        Review(courseId: 'c1', studentId: 's2', studentName: 'B', rating: 3),
        Review(courseId: 'other', studentId: 's4', studentName: 'C', rating: 1),
      ];

      final s = computeCourseStats(course, enrollments, reviews);
      expect(s.enrollments, 3);
      expect(s.completions, 1);
      expect(s.completionRate, closeTo(1 / 3, 1e-9));
      expect(s.avgProgress, closeTo((1.0 + 0.5 + 0.0) / 3, 1e-9));
      expect(s.quizAttempts, 2);
      expect(s.avgQuizScore, closeTo(70, 1e-9));
      expect(s.reviewCount, 2);
      expect(s.avgRating, closeTo(4, 1e-9));
    });
  });

  group('computeInstructorStats', () {
    test('aggregates across courses and counts unique students', () {
      final c1 = _course('c1', lessons: 2);
      final c2 = _course('c2', lessons: 1);
      final enrollments = [
        Enrollment(
          studentId: 's1',
          courseId: 'c1',
          completedLessonIds: c1.lessons.map((l) => l.id).toList(),
        ),
        Enrollment(studentId: 's2', courseId: 'c1'),
        Enrollment(
          studentId: 's1',
          courseId: 'c2',
          completedLessonIds: c2.lessons.map((l) => l.id).toList(),
        ),
      ];
      final reviews = [
        Review(courseId: 'c1', studentId: 's1', studentName: 'A', rating: 4),
        Review(courseId: 'c2', studentId: 's1', studentName: 'A', rating: 2),
      ];

      final s = computeInstructorStats([c1, c2], enrollments, reviews);
      expect(s.totalCourses, 2);
      expect(s.totalEnrollments, 3);
      expect(s.uniqueStudents, 2); // s1 counted once
      expect(s.totalCompletions, 2);
      expect(s.overallCompletionRate, closeTo(2 / 3, 1e-9));
      expect(s.avgRating, closeTo(3, 1e-9));
    });

    test('no courses yields empty stats', () {
      final s = computeInstructorStats([], [], []);
      expect(s.totalCourses, 0);
      expect(s.totalEnrollments, 0);
      expect(s.overallCompletionRate, 0);
      expect(s.avgRating, isNull);
    });
  });
}
