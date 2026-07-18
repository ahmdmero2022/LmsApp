import 'package:uuid/uuid.dart';

class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrolledAt;
  final List<String> completedLessonIds;

  Enrollment({
    String? id,
    required this.studentId,
    required this.courseId,
    DateTime? enrolledAt,
    List<String>? completedLessonIds,
  })  : id = id ?? const Uuid().v4(),
        enrolledAt = enrolledAt ?? DateTime.now(),
        completedLessonIds = completedLessonIds ?? <String>[];

  double progress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return (completedLessonIds.length / totalLessons).clamp(0.0, 1.0);
  }

  bool isCompleted(int totalLessons) =>
      totalLessons > 0 && completedLessonIds.length >= totalLessons;

  Enrollment copyWith({List<String>? completedLessonIds}) {
    return Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId,
      enrolledAt: enrolledAt,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'enrolledAt': enrolledAt.toIso8601String(),
      'completedLessonIds': completedLessonIds,
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] as String,
      studentId: map['studentId'] as String,
      courseId: map['courseId'] as String,
      enrolledAt:
          DateTime.tryParse(map['enrolledAt'] as String? ?? '') ??
              DateTime.now(),
      completedLessonIds: (map['completedLessonIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
