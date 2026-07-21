import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/utils/course_images.dart';

void main() {
  group('defaultCourseImage keyword matching', () {
    test('matches topics on whole words', () {
      expect(defaultCourseImage('Mobile Development'),
          defaultCourseImage('Flutter for Beginners'));
      expect(defaultCourseImage('Databases 101'),
          defaultCourseImage('Intro to SQL'));
      expect(defaultCourseImage('UI/UX Design Principles'),
          defaultCourseImage('Design'));
    });

    test('does not false-match short keywords inside longer words', () {
      // "started"/"smart" must NOT be treated as design ("art").
      expect(defaultCourseImage('Getting Started with Python'),
          isNot(defaultCourseImage('Design')));
      // "application" is mobile-related, but "happen" must not be.
      expect(defaultCourseImage('What could happen'),
          defaultCourseImage(''));
      // "capital" must not match backend ("api").
      expect(defaultCourseImage('Managing Capital'),
          isNot(defaultCourseImage('REST API Design')));
    });

    test('falls back to the default image for unknown topics', () {
      expect(defaultCourseImage('History of Music'),
          defaultCourseImage('anything else entirely'));
    });
  });
}
