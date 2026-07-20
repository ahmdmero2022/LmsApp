import 'package:uuid/uuid.dart';

/// A student's star rating (1-5) and optional comment for a course.
class Review {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    String? id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.rating,
    this.comment = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Review copyWith({int? rating, String? comment, DateTime? createdAt}) {
    return Review(
      id: id,
      courseId: courseId,
      studentId: studentId,
      studentName: studentName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'studentId': studentId,
      'studentName': studentName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      courseId: map['courseId'] as String,
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String? ?? 'Student',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
