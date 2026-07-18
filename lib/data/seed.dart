import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/user.dart';
import 'repositories.dart';

/// Populates the database with a set of demo users, courses and a welcome
/// notification the first time the app runs (when no users exist yet).
class Seeder {
  final UserRepository users;
  final CourseRepository courses;
  final NotificationRepository notifications;

  Seeder({
    required this.users,
    required this.courses,
    required this.notifications,
  });

  Future<void> seedIfEmpty() async {
    final existing = await users.getAll();
    if (existing.isNotEmpty) return;

    const instructor = AppUser(
      id: 'user-instructor-1',
      name: 'Sara Ahmed',
      email: 'sara@lms.dev',
      role: UserRole.instructor,
    );
    const instructor2 = AppUser(
      id: 'user-instructor-2',
      name: 'Omar Khaled',
      email: 'omar@lms.dev',
      role: UserRole.instructor,
    );
    const student = AppUser(
      id: 'user-student-1',
      name: 'Ali Hassan',
      email: 'ali@lms.dev',
      role: UserRole.student,
    );

    for (final u in [instructor, instructor2, student]) {
      await users.save(u);
    }

    final flutter = Course(
      title: 'Flutter for Beginners',
      description:
          'Build cross-platform apps with Flutter and Dart, from widgets '
          'to state management.',
      category: 'Mobile Development',
      instructorId: instructor.id,
      instructorName: instructor.name,
      colorValue: 0xFF1565C0,
      lessons: [
        Lesson(
          title: 'What is Flutter?',
          content:
              'Flutter is an open-source UI toolkit by Google for building '
              'natively compiled applications from a single codebase.',
          durationMinutes: 8,
        ),
        Lesson(
          title: 'Widgets & Layouts',
          content:
              'Everything in Flutter is a widget. Learn Row, Column, Stack '
              'and how to compose responsive layouts.',
          durationMinutes: 15,
        ),
        Lesson(
          title: 'State Management with Provider',
          content:
              'Use ChangeNotifier and Provider to share and rebuild state '
              'across your widget tree efficiently.',
          durationMinutes: 20,
        ),
      ],
    );

    final databases = Course(
      title: 'Databases 101',
      description:
          'Understand relational vs NoSQL databases, modeling data and '
          'writing efficient queries.',
      category: 'Backend',
      instructorId: instructor2.id,
      instructorName: instructor2.name,
      colorValue: 0xFF2E7D32,
      lessons: [
        Lesson(
          title: 'Relational Models',
          content:
              'Tables, rows, primary and foreign keys, and normalization '
              'basics.',
          durationMinutes: 12,
        ),
        Lesson(
          title: 'NoSQL & Document Stores',
          content:
              'Key-value, document and column stores — when and why to use '
              'them.',
          durationMinutes: 14,
        ),
      ],
    );

    final design = Course(
      title: 'UI/UX Design Principles',
      description:
          'Learn the fundamentals of designing intuitive, accessible and '
          'beautiful interfaces.',
      category: 'Design',
      instructorId: instructor.id,
      instructorName: instructor.name,
      colorValue: 0xFF6A1B9A,
      lessons: [
        Lesson(
          title: 'Color & Typography',
          content:
              'Choosing palettes and type scales that improve readability '
              'and hierarchy.',
          durationMinutes: 10,
        ),
        Lesson(
          title: 'Designing for Accessibility',
          content:
              'Contrast ratios, semantics and inclusive design for all '
              'users.',
          durationMinutes: 13,
        ),
      ],
    );

    for (final c in [flutter, databases, design]) {
      await courses.save(c);
    }

    await notifications.save(
      AppNotification(
        userId: student.id,
        title: 'Welcome to the LMS!',
        body:
            'Browse the catalog and enroll in your first course to get '
            'started.',
        type: NotificationType.system,
      ),
    );
  }
}
