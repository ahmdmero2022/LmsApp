import 'package:sembast/sembast.dart';

import '../models/activity.dart';
import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/discussion.dart';
import '../models/enrollment.dart';
import '../models/lesson_note.dart';
import '../models/review.dart';
import '../models/user.dart';
import 'database.dart';

class UserRepository {
  final AppDatabase _db;
  UserRepository(this._db);

  Future<List<AppUser>> getAll() async {
    final db = await _db.database;
    final records = await _db.users.find(db);
    return records.map((r) => AppUser.fromMap(r.value)).toList();
  }

  Future<AppUser?> findByEmail(String email) async {
    final db = await _db.database;
    final finder = Finder(
      filter: Filter.equals('email', email.toLowerCase().trim()),
    );
    final record = await _db.users.findFirst(db, finder: finder);
    return record == null ? null : AppUser.fromMap(record.value);
  }

  Future<void> save(AppUser user) async {
    final db = await _db.database;
    await _db.users.record(user.id).put(db, user.toMap());
  }
}

class CourseRepository {
  final AppDatabase _db;
  CourseRepository(this._db);

  Future<List<Course>> getAll() async {
    final db = await _db.database;
    final records = await _db.courses.find(db);
    final courses = records.map((r) => Course.fromMap(r.value)).toList();
    courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return courses;
  }

  Future<void> save(Course course) async {
    final db = await _db.database;
    await _db.courses.record(course.id).put(db, course.toMap());
  }

  Future<void> delete(String courseId) async {
    final db = await _db.database;
    await _db.courses.record(courseId).delete(db);
  }
}

class EnrollmentRepository {
  final AppDatabase _db;
  EnrollmentRepository(this._db);

  Future<List<Enrollment>> getAll() async {
    final db = await _db.database;
    final records = await _db.enrollments.find(db);
    return records.map((r) => Enrollment.fromMap(r.value)).toList();
  }

  Future<void> save(Enrollment enrollment) async {
    final db = await _db.database;
    await _db.enrollments.record(enrollment.id).put(db, enrollment.toMap());
  }

  Future<void> delete(String enrollmentId) async {
    final db = await _db.database;
    await _db.enrollments.record(enrollmentId).delete(db);
  }
}

class NotificationRepository {
  final AppDatabase _db;
  NotificationRepository(this._db);

  Future<List<AppNotification>> getAll() async {
    final db = await _db.database;
    final records = await _db.notifications.find(db);
    final items =
        records.map((r) => AppNotification.fromMap(r.value)).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> save(AppNotification notification) async {
    final db = await _db.database;
    await _db.notifications
        .record(notification.id)
        .put(db, notification.toMap());
  }

  Future<void> saveAll(List<AppNotification> notifications) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final n in notifications) {
        await _db.notifications.record(n.id).put(txn, n.toMap());
      }
    });
  }
}

class ReviewRepository {
  final AppDatabase _db;
  ReviewRepository(this._db);

  Future<List<Review>> getAll() async {
    final db = await _db.database;
    final records = await _db.reviews.find(db);
    return records.map((r) => Review.fromMap(r.value)).toList();
  }

  Future<void> save(Review review) async {
    final db = await _db.database;
    await _db.reviews.record(review.id).put(db, review.toMap());
  }

  Future<void> delete(String reviewId) async {
    final db = await _db.database;
    await _db.reviews.record(reviewId).delete(db);
  }
}

class DiscussionRepository {
  final AppDatabase _db;
  DiscussionRepository(this._db);

  Future<List<DiscussionPost>> getAll() async {
    final db = await _db.database;
    final records = await _db.discussions.find(db);
    return records.map((r) => DiscussionPost.fromMap(r.value)).toList();
  }

  Future<void> save(DiscussionPost post) async {
    final db = await _db.database;
    await _db.discussions.record(post.id).put(db, post.toMap());
  }

  Future<void> delete(String postId) async {
    final db = await _db.database;
    await _db.discussions.record(postId).delete(db);
  }

  /// Removes a question and all of its replies in one transaction.
  Future<void> deleteThread(String questionId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await _db.discussions.record(questionId).delete(txn);
      final replies = await _db.discussions.find(
        txn,
        finder: Finder(filter: Filter.equals('parentId', questionId)),
      );
      for (final r in replies) {
        await _db.discussions.record(r.key).delete(txn);
      }
    });
  }
}

class NoteRepository {
  final AppDatabase _db;
  NoteRepository(this._db);

  Future<List<LessonNote>> getAll() async {
    final db = await _db.database;
    final records = await _db.notes.find(db);
    return records.map((r) => LessonNote.fromMap(r.value)).toList();
  }

  Future<void> save(LessonNote note) async {
    final db = await _db.database;
    await _db.notes.record(note.id).put(db, note.toMap());
  }

  Future<void> delete(String noteId) async {
    final db = await _db.database;
    await _db.notes.record(noteId).delete(db);
  }
}

class ActivityRepository {
  final AppDatabase _db;
  ActivityRepository(this._db);

  Future<List<ActivityDay>> getAll() async {
    final db = await _db.database;
    final records = await _db.activity.find(db);
    return records.map((r) => ActivityDay.fromMap(r.value)).toList();
  }

  /// Idempotent: keyed by user + day so re-recording the same day is a no-op.
  Future<void> save(ActivityDay day) async {
    final db = await _db.database;
    await _db.activity.record(day.id).put(db, day.toMap());
  }
}

/// Persists small app-wide preferences (e.g. selected language) as a single
/// key/value record.
class SettingsRepository {
  static const String _key = 'app';

  final AppDatabase _db;
  SettingsRepository(this._db);

  Future<String?> getString(String field) async {
    final db = await _db.database;
    final record = await _db.settings.record(_key).get(db);
    final value = record?[field];
    return value is String ? value : null;
  }

  Future<void> setString(String field, String? value) async {
    final db = await _db.database;
    if (value == null) {
      await _db.settings.record(_key).update(db, {field: FieldValue.delete});
    } else {
      await _db.settings.record(_key).put(db, {field: value}, merge: true);
    }
  }
}
