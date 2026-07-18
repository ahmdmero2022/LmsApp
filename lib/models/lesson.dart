import 'package:uuid/uuid.dart';

class Lesson {
  final String id;
  final String title;
  final String content;
  final int durationMinutes;

  Lesson({
    String? id,
    required this.title,
    required this.content,
    this.durationMinutes = 10,
  }) : id = id ?? const Uuid().v4();

  Lesson copyWith({String? title, String? content, int? durationMinutes}) {
    return Lesson(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'durationMinutes': durationMinutes,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 10,
    );
  }
}
