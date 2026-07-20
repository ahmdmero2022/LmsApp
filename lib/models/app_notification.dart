import 'package:uuid/uuid.dart';

enum NotificationType {
  enrollment,
  newCourse,
  newLesson,
  progress,
  quiz,
  review,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool read;
  final String? courseId;

  AppNotification({
    String? id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    DateTime? createdAt,
    this.read = false,
    this.courseId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      read: read ?? this.read,
      courseId: courseId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'read': read,
      'courseId': courseId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
              DateTime.now(),
      read: map['read'] as bool? ?? false,
      courseId: map['courseId'] as String?,
    );
  }
}
