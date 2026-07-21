import 'package:uuid/uuid.dart';

/// A single message in a course discussion. Top-level posts (questions) have a
/// null [parentId]; replies point to the question they answer.
class DiscussionPost {
  final String id;
  final String courseId;
  final String authorId;
  final String authorName;
  final String message;
  final String? parentId;
  final DateTime createdAt;

  DiscussionPost({
    String? id,
    required this.courseId,
    required this.authorId,
    required this.authorName,
    required this.message,
    this.parentId,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isReply => parentId != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'courseId': courseId,
        'authorId': authorId,
        'authorName': authorName,
        'message': message,
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DiscussionPost.fromMap(Map<String, dynamic> map) => DiscussionPost(
        id: map['id'] as String,
        courseId: map['courseId'] as String,
        authorId: map['authorId'] as String,
        authorName: map['authorName'] as String? ?? 'User',
        message: map['message'] as String? ?? '',
        parentId: map['parentId'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A question with its replies, ready for display.
class DiscussionThread {
  final DiscussionPost question;
  final List<DiscussionPost> replies;
  const DiscussionThread({required this.question, required this.replies});
}

/// Groups [posts] belonging to [courseId] into question threads: questions
/// oldest-first, each carrying its replies in chronological order.
List<DiscussionThread> buildThreads(
  Iterable<DiscussionPost> posts,
  String courseId,
) {
  final scoped = posts.where((p) => p.courseId == courseId).toList();
  final questions = scoped.where((p) => !p.isReply).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return [
    for (final q in questions)
      DiscussionThread(
        question: q,
        replies: scoped.where((p) => p.parentId == q.id).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      ),
  ];
}
