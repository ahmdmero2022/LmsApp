import 'package:uuid/uuid.dart';

import 'lesson.dart';
import 'quiz.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String instructorId;
  final String instructorName;
  final int colorValue;
  final List<Lesson> lessons;
  final List<QuizQuestion> quiz;
  final DateTime createdAt;

  Course({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    required this.instructorId,
    required this.instructorName,
    required this.colorValue,
    List<Lesson>? lessons,
    List<QuizQuestion>? quiz,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        lessons = lessons ?? <Lesson>[],
        quiz = quiz ?? <QuizQuestion>[],
        createdAt = createdAt ?? DateTime.now();

  int get totalMinutes =>
      lessons.fold(0, (sum, l) => sum + l.durationMinutes);

  bool get hasQuiz => quiz.isNotEmpty;

  Course copyWith({
    String? title,
    String? description,
    String? category,
    int? colorValue,
    List<Lesson>? lessons,
    List<QuizQuestion>? quiz,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      instructorId: instructorId,
      instructorName: instructorName,
      colorValue: colorValue ?? this.colorValue,
      lessons: lessons ?? this.lessons,
      quiz: quiz ?? this.quiz,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'colorValue': colorValue,
      'lessons': lessons.map((l) => l.toMap()).toList(),
      'quiz': quiz.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      instructorId: map['instructorId'] as String,
      instructorName: map['instructorName'] as String? ?? 'Unknown',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF6750A4,
      lessons: (map['lessons'] as List<dynamic>? ?? [])
          .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      quiz: (map['quiz'] as List<dynamic>? ?? [])
          .map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
