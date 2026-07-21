import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/course.dart';
import '../../../models/lesson.dart';
import '../../../state/app_state.dart';
import '../../../widgets/media_embed.dart';

/// Shows the create/edit lesson dialog. When [existing] is provided the dialog
/// pre-fills its fields and saves via `updateLesson`; otherwise it adds a new
/// lesson.
Future<void> showLessonDialog(
  BuildContext context,
  Course course, {
  Lesson? existing,
}) async {
  final state = context.read<AppState>();
  final isEdit = existing != null;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final contentCtrl = TextEditingController(text: existing?.content ?? '');
  final urlCtrl = TextEditingController(text: existing?.url ?? '');
  final durationCtrl = TextEditingController(
    text: '${existing?.durationMinutes ?? 10}',
  );
  var type = existing?.type ?? LessonType.text;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit lesson' : 'Add lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<LessonType>(
                  segments: const [
                    ButtonSegment(
                      value: LessonType.text,
                      label: Text('Reading'),
                      icon: Icon(Icons.article),
                    ),
                    ButtonSegment(
                      value: LessonType.video,
                      label: Text('Video'),
                      icon: Icon(Icons.play_circle),
                    ),
                    ButtonSegment(
                      value: LessonType.pdf,
                      label: Text('PDF'),
                      icon: Icon(Icons.picture_as_pdf),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) =>
                      setDialogState(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                if (type == LessonType.text)
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Content'),
                  )
                else ...[
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      labelText: type == LessonType.video
                          ? 'Video URL (YouTube or .mp4)'
                          : 'PDF URL',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Caption (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

  final needsUrl = type != LessonType.text;
  if (result == true &&
      titleCtrl.text.trim().isNotEmpty &&
      (!needsUrl || urlCtrl.text.trim().isNotEmpty)) {
    final lesson = Lesson(
      id: existing?.id,
      title: titleCtrl.text.trim(),
      type: type,
      content: contentCtrl.text.trim(),
      url: urlCtrl.text.trim(),
      durationMinutes: int.tryParse(durationCtrl.text.trim()) ?? 10,
    );
    if (isEdit) {
      await state.updateLesson(course, lesson);
    } else {
      await state.addLesson(course, lesson);
    }
  }
}

class LessonTile extends StatelessWidget {
  final Course course;
  final Lesson lesson;
  final int index;
  final bool enrolled;
  final bool isOwner;
  final bool completed;

  const LessonTile({
    super.key,
    required this.course,
    required this.lesson,
    required this.index,
    required this.enrolled,
    required this.isOwner,
    required this.completed,
  });

  IconData get _typeIcon {
    switch (lesson.type) {
      case LessonType.text:
        return Icons.article_outlined;
      case LessonType.video:
        return Icons.play_circle_outline;
      case LessonType.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: completed
              ? Colors.green
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: completed ? Colors.white : null,
          child:
              completed ? const Icon(Icons.check) : Text('${index + 1}'),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(_typeIcon, size: 14),
            const SizedBox(width: 4),
            Text('${lesson.type.label} · ${lesson.durationMinutes} min'),
          ],
        ),
        trailing: isOwner
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit lesson',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        showLessonDialog(context, course, existing: lesson),
                  ),
                  IconButton(
                    tooltip: 'Delete lesson',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context),
                  ),
                  const Icon(Icons.expand_more),
                ],
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.isMedia && lesson.url.isNotEmpty) ...[
            buildMediaEmbed(
              url: lesson.url,
              isVideo: lesson.type == LessonType.video,
              height: lesson.type == LessonType.video ? 260 : 420,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _open(lesson.url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in new tab'),
              ),
            ),
            if (lesson.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(lesson.content),
            ],
          ] else
            Text(lesson.content),
          if (enrolled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    state.toggleLessonComplete(course, lesson),
                icon: Icon(completed ? Icons.undo : Icons.check_circle),
                label: Text(
                  completed ? 'Mark as not done' : 'Mark complete',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete lesson?'),
        content: Text('This will remove "${lesson.title}" from the course.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteLesson(course, lesson.id);
    }
  }
}
