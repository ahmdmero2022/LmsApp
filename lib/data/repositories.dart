import 'package:sembast/sembast.dart';

import '../models/app_notification.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
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
