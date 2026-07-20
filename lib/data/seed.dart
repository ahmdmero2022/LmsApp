import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../utils/password.dart';
import 'repositories.dart';

/// Password shared by every seeded demo account.
const String kDemoPassword = 'password123';

/// Emails of the seeded demo accounts.
const List<String> kDemoEmails = ['sara@lms.dev', 'omar@lms.dev', 'ali@lms.dev'];

/// Builds a demo [AppUser] with [kDemoPassword] already hashed.
AppUser _demoUser({
  required String id,
  required String name,
  required String email,
  required UserRole role,
}) {
  final salt = generateSalt();
  return AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    passwordSalt: salt,
    passwordHash: hashPassword(kDemoPassword, salt),
  );
}

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

  /// Backfills a hashed [kDemoPassword] onto demo accounts that were seeded
  /// before password auth existed, so the advertised demo password works for
  /// installations created before this feature.
  Future<void> backfillDemoPasswords() async {
    for (final email in kDemoEmails) {
      final user = await users.findByEmail(email);
      if (user != null && !user.hasPassword) {
        final salt = generateSalt();
        await users.save(
          user.copyWith(
            passwordSalt: salt,
            passwordHash: hashPassword(kDemoPassword, salt),
          ),
        );
      }
    }
  }

  Future<void> seedIfEmpty() async {
    final existing = await users.getAll();
    if (existing.isNotEmpty) return;

    final instructor = _demoUser(
      id: 'user-instructor-1',
      name: 'Sara Ahmed',
      email: 'sara@lms.dev',
      role: UserRole.instructor,
    );
    final instructor2 = _demoUser(
      id: 'user-instructor-2',
      name: 'Omar Khaled',
      email: 'omar@lms.dev',
      role: UserRole.instructor,
    );
    final student = _demoUser(
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
        Lesson(
          title: 'Intro Video: Flutter in 100 seconds',
          type: LessonType.video,
          url: 'https://www.youtube.com/watch?v=lHhRhPV--G0',
          content: 'A quick overview of what Flutter is and why it exists.',
          durationMinutes: 3,
        ),
        Lesson(
          title: 'Reference: Dart cheat sheet (PDF)',
          type: LessonType.pdf,
          url:
              'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf',
          content: 'Keep this handy while you code.',
          durationMinutes: 5,
        ),
      ],
      quiz: [
        QuizQuestion(
          prompt: 'What language are Flutter apps written in?',
          options: ['Dart', 'JavaScript', 'Kotlin', 'Swift'],
          correctIndex: 0,
        ),
        QuizQuestion(
          prompt: 'In Flutter, almost everything on screen is a…',
          options: ['Widget', 'Component', 'Fragment', 'Template'],
          correctIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which package is commonly used for state management?',
          options: ['provider', 'express', 'redux-saga', 'axios'],
          correctIndex: 0,
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
      quiz: [
        QuizQuestion(
          prompt: 'Which key uniquely identifies a row in a table?',
          options: ['Primary key', 'Foreign key', 'Index', 'View'],
          correctIndex: 0,
        ),
        QuizQuestion(
          prompt: 'MongoDB is an example of which kind of database?',
          options: ['Document store', 'Relational', 'Graph', 'Spreadsheet'],
          correctIndex: 0,
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
