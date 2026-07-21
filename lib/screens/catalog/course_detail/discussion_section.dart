import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/course.dart';
import '../../../models/discussion.dart';
import '../../../state/app_state.dart';

class DiscussionSection extends StatelessWidget {
  final Course course;
  final bool enrolled;
  final bool isOwner;

  const DiscussionSection({
    super.key,
    required this.course,
    required this.enrolled,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final threads = state.discussionThreads(course.id);
    final canPost = enrolled || isOwner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined),
            const SizedBox(width: 8),
            Text(
              'Discussion (${state.discussionCount(course.id)})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (canPost)
          _Composer(
            hint: 'Ask a question…',
            buttonLabel: 'Post question',
            onSubmit: (text) => state.postDiscussion(course, message: text),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Enroll to join the discussion.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (threads.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No questions yet.'),
            ),
          )
        else
          for (final thread in threads)
            _ThreadCard(
              course: course,
              thread: thread,
              canReply: canPost,
            ),
      ],
    );
  }
}

class _ThreadCard extends StatelessWidget {
  final Course course;
  final DiscussionThread thread;
  final bool canReply;

  const _ThreadCard({
    required this.course,
    required this.thread,
    required this.canReply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostBody(course: course, post: thread.question, isQuestion: true),
            if (thread.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  children: [
                    for (final reply in thread.replies)
                      _PostBody(
                        course: course,
                        post: reply,
                        isQuestion: false,
                      ),
                  ],
                ),
              ),
            if (canReply)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: _Composer(
                  hint: 'Reply…',
                  buttonLabel: 'Reply',
                  dense: true,
                  onSubmit: (text) => context.read<AppState>().postDiscussion(
                        course,
                        message: text,
                        parentId: thread.question.id,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  final Course course;
  final DiscussionPost post;
  final bool isQuestion;

  const _PostBody({
    required this.course,
    required this.post,
    required this.isQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final me = state.currentUser;
    final isInstructor = post.authorId == course.instructorId;
    final canDelete =
        me != null && (post.authorId == me.id || course.instructorId == me.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                isInstructor ? scheme.tertiaryContainer : scheme.primaryContainer,
            child: Text(
              post.authorName.isNotEmpty
                  ? post.authorName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isInstructor
                    ? scheme.onTertiaryContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isInstructor) ...[
                      const SizedBox(width: 6),
                      _InstructorChip(scheme: scheme),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(post.message),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => state.deleteDiscussion(course, post),
            ),
        ],
      ),
    );
  }
}

class _InstructorChip extends StatelessWidget {
  final ColorScheme scheme;
  const _InstructorChip({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Instructor',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  final String hint;
  final String buttonLabel;
  final bool dense;
  final Future<void> Function(String text) onSubmit;

  const _Composer({
    required this.hint,
    required this.buttonLabel,
    required this.onSubmit,
    this.dense = false,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    await widget.onSubmit(text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: widget.dense,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
