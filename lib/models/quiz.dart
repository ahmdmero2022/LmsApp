import 'package:uuid/uuid.dart';

/// A single multiple-choice question belonging to a course quiz.
class QuizQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    String? id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  }) : id = id ?? const Uuid().v4();

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  QuizQuestion copyWith({
    String? prompt,
    List<String>? options,
    int? correctIndex,
  }) {
    return QuizQuestion(
      id: id,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String,
      prompt: map['prompt'] as String? ?? '',
      options: (map['options'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
