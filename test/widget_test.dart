import 'package:flutter_test/flutter_test.dart';

import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/enrollment.dart';
import 'package:lms_app/models/lesson.dart';

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
  });
}
