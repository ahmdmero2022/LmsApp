import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/models/discussion.dart';
import 'package:lms_app/models/lesson_note.dart';

DiscussionPost _post(
  String id, {
  required String courseId,
  String? parentId,
  required int minute,
}) =>
    DiscussionPost(
      id: id,
      courseId: courseId,
      authorId: 'a',
      authorName: 'A',
      message: 'm$id',
      parentId: parentId,
      createdAt: DateTime(2026, 1, 1, 0, minute),
    );

void main() {
  group('buildThreads', () {
    test('empty posts yield no threads', () {
      expect(buildThreads(const [], 'c1'), isEmpty);
    });

    test('groups replies under their question and ignores other courses', () {
      final posts = [
        _post('q1', courseId: 'c1', minute: 1),
        _post('r1', courseId: 'c1', parentId: 'q1', minute: 3),
        _post('r2', courseId: 'c1', parentId: 'q1', minute: 2),
        _post('q2', courseId: 'c1', minute: 5),
        _post('other', courseId: 'c2', minute: 1),
      ];
      final threads = buildThreads(posts, 'c1');
      expect(threads.length, 2);
      // Questions sorted oldest first.
      expect(threads[0].question.id, 'q1');
      expect(threads[1].question.id, 'q2');
      // Replies sorted chronologically.
      expect(threads[0].replies.map((p) => p.id).toList(), ['r2', 'r1']);
      expect(threads[1].replies, isEmpty);
    });

    test('a reply whose parent is absent produces no orphan thread', () {
      final threads = buildThreads(
        [_post('r1', courseId: 'c1', parentId: 'missing', minute: 1)],
        'c1',
      );
      expect(threads, isEmpty);
    });
  });

  group('serialization', () {
    test('DiscussionPost round-trips through a map', () {
      final p = _post('q1', courseId: 'c1', parentId: 'x', minute: 4);
      final back = DiscussionPost.fromMap(p.toMap());
      expect(back.id, p.id);
      expect(back.courseId, 'c1');
      expect(back.parentId, 'x');
      expect(back.isReply, isTrue);
      expect(back.createdAt, p.createdAt);
    });

    test('LessonNote key and round-trip are stable', () {
      final note = LessonNote(
        userId: 'u1',
        courseId: 'c1',
        lessonId: 'l1',
        text: 'hello',
      );
      expect(note.id, 'u1|l1');
      expect(LessonNote.key('u1', 'l1'), note.id);
      final back = LessonNote.fromMap(note.toMap());
      expect(back.userId, 'u1');
      expect(back.lessonId, 'l1');
      expect(back.text, 'hello');
    });
  });
}
