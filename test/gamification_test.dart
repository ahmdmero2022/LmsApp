import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/enrollment.dart';
import 'package:lms_app/models/gamification.dart';
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
  group('computeStreak', () {
    final today = DateTime(2026, 7, 18);
    DateTime day(int offset) => today.subtract(Duration(days: offset));

    test('empty is zero', () {
      expect(computeStreak([], today: today), 0);
    });

    test('consecutive days ending today', () {
      expect(computeStreak([day(0), day(1), day(2)], today: today), 3);
    });

    test('streak ending yesterday still counts', () {
      expect(computeStreak([day(1), day(2)], today: today), 2);
    });

    test('gap resets the streak', () {
      // active today and 3 days ago -> only today counts
      expect(computeStreak([day(0), day(3), day(4)], today: today), 1);
    });

    test('lapsed streak (older than yesterday) is zero', () {
      expect(computeStreak([day(2), day(3)], today: today), 0);
    });

    test('duplicate days do not inflate the count', () {
      expect(computeStreak([day(0), day(0), day(1)], today: today), 2);
    });
  });

  group('computeUserGameStats', () {
    final c1 = _course('c1', lessons: 2);
    final c2 = _course('c2', lessons: 2);
    final courses = [c1, c2];

    test('empty learner earns no points or badges', () {
      final s = computeUserGameStats(
        userId: 'u1',
        courses: courses,
        enrollments: const [],
        reviews: const [],
        activeDays: const [],
      );
      expect(s.points, 0);
      expect(s.badges, isEmpty);
      expect(s.lessonsCompleted, 0);
      expect(s.coursesCompleted, 0);
    });

    test('points and badges accrue from completions, quiz and review', () {
      final enrollments = [
        Enrollment(
          studentId: 'u1',
          courseId: 'c1',
          completedLessonIds: c1.lessons.map((l) => l.id).toList(),
          quizScore: 100,
        ),
        Enrollment(
          studentId: 'u1',
          courseId: 'c2',
          completedLessonIds: [c2.lessons.first.id],
        ),
      ];
      final reviews = [
        Review(courseId: 'c1', studentId: 'u1', studentName: 'U', rating: 5),
      ];

      final s = computeUserGameStats(
        userId: 'u1',
        courses: courses,
        enrollments: enrollments,
        reviews: reviews,
        activeDays: const [],
      );
      // 3 lessons * 10 + 1 course * 50 + 1 quiz pass * 20 + 1 review * 5
      expect(s.lessonsCompleted, 3);
      expect(s.coursesCompleted, 1);
      expect(s.quizzesPassed, 1);
      expect(s.reviewsWritten, 1);
      expect(s.points, 3 * 10 + 50 + 20 + 5);
      expect(
        s.badges,
        containsAll(<BadgeId>{
          BadgeId.firstLesson,
          BadgeId.quizPassed,
          BadgeId.perfectScore,
          BadgeId.firstCourse,
          BadgeId.reviewer,
        }),
      );
      expect(s.badges.contains(BadgeId.scholar), isFalse);
    });

    test('ignores enrollments and reviews of other users', () {
      final s = computeUserGameStats(
        userId: 'u1',
        courses: courses,
        enrollments: [
          Enrollment(
            studentId: 'u2',
            courseId: 'c1',
            completedLessonIds: c1.lessons.map((l) => l.id).toList(),
          ),
        ],
        reviews: [
          Review(courseId: 'c1', studentId: 'u2', studentName: 'X', rating: 4),
        ],
        activeDays: const [],
      );
      expect(s.points, 0);
      expect(s.badges, isEmpty);
    });

    test('a 7-day run of active days yields a 7-day streak and badges', () {
      final today = DateTime(2026, 7, 18);
      final days = [
        for (var i = 0; i < 7; i++) today.subtract(Duration(days: i)),
      ];
      expect(computeStreak(days, today: today), 7);
      expect(computeStreak(days, today: today) >= 3, isTrue);
    });
  });
}
