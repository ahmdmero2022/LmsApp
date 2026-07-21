/// A private, per-user free-text note attached to a lesson. Only its author can
/// see it. Keyed by user + lesson so each learner keeps one note per lesson.
class LessonNote {
  final String userId;
  final String courseId;
  final String lessonId;
  final String text;
  final DateTime updatedAt;

  LessonNote({
    required this.userId,
    required this.courseId,
    required this.lessonId,
    required this.text,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get id => key(userId, lessonId);

  static String key(String userId, String lessonId) => '$userId|$lessonId';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courseId': courseId,
        'lessonId': lessonId,
        'text': text,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LessonNote.fromMap(Map<String, dynamic> map) => LessonNote(
        userId: map['userId'] as String,
        courseId: map['courseId'] as String,
        lessonId: map['lessonId'] as String,
        text: map['text'] as String? ?? '',
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
