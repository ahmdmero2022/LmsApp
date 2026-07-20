import 'package:uuid/uuid.dart';

/// The kind of content a lesson delivers.
enum LessonType { text, video, pdf }

extension LessonTypeLabel on LessonType {
  String get label {
    switch (this) {
      case LessonType.text:
        return 'Reading';
      case LessonType.video:
        return 'Video';
      case LessonType.pdf:
        return 'PDF';
    }
  }
}

class Lesson {
  final String id;
  final String title;
  final LessonType type;

  /// Text body for reading lessons; used as an optional caption for media.
  final String content;

  /// Media URL for [LessonType.video] and [LessonType.pdf] lessons.
  final String url;
  final int durationMinutes;

  Lesson({
    String? id,
    required this.title,
    this.type = LessonType.text,
    this.content = '',
    this.url = '',
    this.durationMinutes = 10,
  }) : id = id ?? const Uuid().v4();

  bool get isMedia => type == LessonType.video || type == LessonType.pdf;

  Lesson copyWith({
    String? title,
    LessonType? type,
    String? content,
    String? url,
    int? durationMinutes,
  }) {
    return Lesson(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      url: url ?? this.url,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'content': content,
      'url': url,
      'durationMinutes': durationMinutes,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      title: map['title'] as String,
      type: LessonType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => LessonType.text,
      ),
      content: map['content'] as String? ?? '',
      url: map['url'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 10,
    );
  }
}
