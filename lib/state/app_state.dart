import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/repositories.dart';
import '../data/seed.dart';
import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../utils/password.dart';

/// Holds the entire in-memory view of the app and mediates every write to the
/// persistent database. UI listens to this via `provider`.
class AppState extends ChangeNotifier {
  final UserRepository _users;
  final CourseRepository _courses;
  final EnrollmentRepository _enrollments;
  final NotificationRepository _notifications;

  AppState({
    UserRepository? users,
    CourseRepository? courses,
    EnrollmentRepository? enrollments,
    NotificationRepository? notifications,
  })  : _users = users ?? UserRepository(AppDatabase.instance),
        _courses = courses ?? CourseRepository(AppDatabase.instance),
        _enrollments =
            enrollments ?? EnrollmentRepository(AppDatabase.instance),
        _notifications =
            notifications ?? NotificationRepository(AppDatabase.instance);

  bool _loading = true;
  bool get loading => _loading;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInstructor => _currentUser?.role == UserRole.instructor;

  List<AppUser> _allUsers = [];
  List<Course> _allCourses = [];
  List<Enrollment> _allEnrollments = [];
  List<AppNotification> _allNotifications = [];

  List<AppUser> get allUsers => List.unmodifiable(_allUsers);
  List<Course> get courses => List.unmodifiable(_allCourses);

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    final seeder = Seeder(
      users: _users,
      courses: _courses,
      notifications: _notifications,
    );
    await seeder.seedIfEmpty();
    await seeder.backfillDemoPasswords();
    await _reloadAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> _reloadAll() async {
    _allUsers = await _users.getAll();
    _allCourses = await _courses.getAll();
    _allEnrollments = await _enrollments.getAll();
    _allNotifications = await _notifications.getAll();
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  Future<bool> login(String email, String password) async {
    final user = await _users.findByEmail(email);
    if (user == null || !user.hasPassword) return false;
    if (!verifyPassword(password, user.passwordSalt!, user.passwordHash!)) {
      return false;
    }
    _currentUser = user;
    await _reloadAll();
    notifyListeners();
    return true;
  }

  void loginAs(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final existing = await _users.findByEmail(email);
    if (existing != null) return null;
    final salt = generateSalt();
    final user = AppUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: email.toLowerCase().trim(),
      role: role,
      passwordSalt: salt,
      passwordHash: hashPassword(password, salt),
    );
    await _users.save(user);
    await _notifications.save(
      AppNotification(
        userId: user.id,
        title: 'Welcome, ${user.name}!',
        body: role == UserRole.instructor
            ? 'Create your first course from the "Teaching" tab.'
            : 'Enroll in a course to start learning.',
        type: NotificationType.system,
      ),
    );
    _currentUser = user;
    await _reloadAll();
    notifyListeners();
    return user;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Changes the signed-in user's password after verifying [currentPassword].
  /// Returns [ChangePasswordResult.success] on success, or a specific failure
  /// reason otherwise.
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) return ChangePasswordResult.notSignedIn;
    if (user.hasPassword &&
        !verifyPassword(
          currentPassword,
          user.passwordSalt!,
          user.passwordHash!,
        )) {
      return ChangePasswordResult.wrongCurrentPassword;
    }
    final salt = generateSalt();
    final updated = user.copyWith(
      passwordSalt: salt,
      passwordHash: hashPassword(newPassword, salt),
    );
    await _users.save(updated);
    _currentUser = updated;
    await _reloadAll();
    notifyListeners();
    return ChangePasswordResult.success;
  }

  // ---------------------------------------------------------------------------
  // Enrollments
  // ---------------------------------------------------------------------------

  List<Enrollment> get myEnrollments {
    final id = _currentUser?.id;
    if (id == null) return [];
    return _allEnrollments.where((e) => e.studentId == id).toList();
  }

  Enrollment? enrollmentFor(String courseId) {
    final id = _currentUser?.id;
    if (id == null) return null;
    for (final e in _allEnrollments) {
      if (e.studentId == id && e.courseId == courseId) return e;
    }
    return null;
  }

  bool isEnrolled(String courseId) => enrollmentFor(courseId) != null;

  int enrollmentCount(String courseId) =>
      _allEnrollments.where((e) => e.courseId == courseId).length;

  Future<void> enroll(Course course) async {
    final student = _currentUser;
    if (student == null || isEnrolled(course.id)) return;
    final enrollment =
        Enrollment(studentId: student.id, courseId: course.id);
    await _enrollments.save(enrollment);
    // Notify the instructor that a new student joined.
    await _notifications.save(
      AppNotification(
        userId: course.instructorId,
        title: 'New enrollment',
        body: '${student.name} enrolled in "${course.title}".',
        type: NotificationType.enrollment,
        courseId: course.id,
      ),
    );
    await _reloadAll();
    notifyListeners();
  }

  Future<void> unenroll(String courseId) async {
    final enrollment = enrollmentFor(courseId);
    if (enrollment == null) return;
    await _enrollments.delete(enrollment.id);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> toggleLessonComplete(Course course, Lesson lesson) async {
    final enrollment = enrollmentFor(course.id);
    if (enrollment == null) return;
    final completed = List<String>.from(enrollment.completedLessonIds);
    final wasComplete = enrollment.isCompleted(course.lessons.length);
    if (completed.contains(lesson.id)) {
      completed.remove(lesson.id);
    } else {
      completed.add(lesson.id);
    }
    var updated = enrollment.copyWith(completedLessonIds: completed);
    final nowComplete = updated.isCompleted(course.lessons.length);
    if (!wasComplete && nowComplete) {
      updated = updated.copyWith(completedAt: DateTime.now());
    }
    await _enrollments.save(updated);

    if (!wasComplete && nowComplete) {
      final student = _currentUser!;
      await _notifications.saveAll([
        AppNotification(
          userId: student.id,
          title: 'Course completed! 🎉',
          body: 'You finished "${course.title}". Great job!',
          type: NotificationType.progress,
          courseId: course.id,
        ),
        AppNotification(
          userId: course.instructorId,
          title: 'Student completed a course',
          body: '${student.name} completed "${course.title}".',
          type: NotificationType.progress,
          courseId: course.id,
        ),
      ]);
    }
    await _reloadAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Instructor: course authoring
  // ---------------------------------------------------------------------------

  List<Course> get myCourses {
    final id = _currentUser?.id;
    if (id == null) return [];
    return _allCourses.where((c) => c.instructorId == id).toList();
  }

  Future<void> createCourse(Course course) async {
    await _courses.save(course);
    // Notify every student a new course is available.
    final students =
        _allUsers.where((u) => u.role == UserRole.student).toList();
    await _notifications.saveAll([
      for (final s in students)
        AppNotification(
          userId: s.id,
          title: 'New course available',
          body: '"${course.title}" by ${course.instructorName} was just '
              'published.',
          type: NotificationType.newCourse,
          courseId: course.id,
        ),
    ]);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    await _courses.save(course);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> deleteCourse(String courseId) async {
    await _courses.delete(courseId);
    for (final e
        in _allEnrollments.where((e) => e.courseId == courseId).toList()) {
      await _enrollments.delete(e.id);
    }
    await _reloadAll();
    notifyListeners();
  }

  Future<void> addLesson(Course course, Lesson lesson) async {
    final updated =
        course.copyWith(lessons: [...course.lessons, lesson]);
    await _courses.save(updated);
    // Notify enrolled students about the new lesson.
    final enrolledStudentIds = _allEnrollments
        .where((e) => e.courseId == course.id)
        .map((e) => e.studentId)
        .toSet();
    await _notifications.saveAll([
      for (final sid in enrolledStudentIds)
        AppNotification(
          userId: sid,
          title: 'New lesson added',
          body: '"${lesson.title}" was added to "${course.title}".',
          type: NotificationType.newLesson,
          courseId: course.id,
        ),
    ]);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> updateLesson(Course course, Lesson lesson) async {
    final updated = course.copyWith(
      lessons: [
        for (final l in course.lessons)
          if (l.id == lesson.id) lesson else l,
      ],
    );
    await _courses.save(updated);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> deleteLesson(Course course, String lessonId) async {
    final updated = course.copyWith(
      lessons: course.lessons.where((l) => l.id != lessonId).toList(),
    );
    await _courses.save(updated);
    // Drop the lesson from any enrollment's completed set so progress stays
    // correct.
    for (final e in _allEnrollments.where((e) => e.courseId == course.id)) {
      if (e.completedLessonIds.contains(lessonId)) {
        await _enrollments.save(
          e.copyWith(
            completedLessonIds:
                e.completedLessonIds.where((id) => id != lessonId).toList(),
          ),
        );
      }
    }
    await _reloadAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Quiz
  // ---------------------------------------------------------------------------

  /// Percentage required to pass a quiz.
  static const double quizPassMark = 60;

  Future<void> addQuizQuestion(Course course, QuizQuestion question) async {
    final wasEmpty = course.quiz.isEmpty;
    final updated = course.copyWith(quiz: [...course.quiz, question]);
    await _courses.save(updated);
    // Alert enrolled students the first time a quiz becomes available.
    if (wasEmpty) {
      final enrolledStudentIds = _allEnrollments
          .where((e) => e.courseId == course.id)
          .map((e) => e.studentId)
          .toSet();
      await _notifications.saveAll([
        for (final sid in enrolledStudentIds)
          AppNotification(
            userId: sid,
            title: 'Quiz available',
            body: 'A quiz was added to "${course.title}". Test your knowledge!',
            type: NotificationType.quiz,
            courseId: course.id,
          ),
      ]);
    }
    await _reloadAll();
    notifyListeners();
  }

  Future<void> updateQuizQuestion(Course course, QuizQuestion question) async {
    final updated = course.copyWith(
      quiz: [
        for (final q in course.quiz)
          if (q.id == question.id) question else q,
      ],
    );
    await _courses.save(updated);
    await _reloadAll();
    notifyListeners();
  }

  Future<void> deleteQuizQuestion(Course course, String questionId) async {
    final updated = course.copyWith(
      quiz: course.quiz.where((q) => q.id != questionId).toList(),
    );
    await _courses.save(updated);
    await _reloadAll();
    notifyListeners();
  }

  /// Records a quiz attempt (keeping the best score) and notifies the student
  /// and, on a pass, the instructor.
  Future<void> submitQuiz(Course course, int correct, int total) async {
    final enrollment = enrollmentFor(course.id);
    final student = _currentUser;
    if (enrollment == null || student == null || total == 0) return;
    final pct = correct / total * 100;
    final previous = enrollment.quizScore;
    final best = previous == null || pct > previous ? pct : previous;
    await _enrollments.save(enrollment.copyWith(quizScore: best));

    final passed = pct >= quizPassMark;
    await _notifications.saveAll([
      AppNotification(
        userId: student.id,
        title: passed ? 'Quiz passed! 🎯' : 'Quiz completed',
        body: 'You scored ${pct.round()}% on the "${course.title}" quiz '
            '($correct/$total correct).',
        type: NotificationType.quiz,
        courseId: course.id,
      ),
      if (passed)
        AppNotification(
          userId: course.instructorId,
          title: 'Student passed a quiz',
          body: '${student.name} scored ${pct.round()}% on the '
              '"${course.title}" quiz.',
          type: NotificationType.quiz,
          courseId: course.id,
        ),
    ]);
    await _reloadAll();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  List<AppNotification> get myNotifications {
    final id = _currentUser?.id;
    if (id == null) return [];
    return _allNotifications.where((n) => n.userId == id).toList();
  }

  int get unreadCount => myNotifications.where((n) => !n.read).length;

  Future<void> markNotificationRead(AppNotification notification) async {
    if (notification.read) return;
    await _notifications.save(notification.copyWith(read: true));
    await _reloadAll();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final unread = myNotifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    await _notifications
        .saveAll([for (final n in unread) n.copyWith(read: true)]);
    await _reloadAll();
    notifyListeners();
  }

  Course? courseById(String? id) {
    if (id == null) return null;
    for (final c in _allCourses) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Outcome of an [AppState.changePassword] attempt.
enum ChangePasswordResult {
  success,
  wrongCurrentPassword,
  notSignedIn,
}
