import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course.dart';
import '../models/lesson.dart';
import '../models/quiz.dart';
import '../state/app_state.dart';
import '../widgets/media_embed.dart';
import 'quiz_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final course = state.courseById(courseId);
    if (course == null) {
      return const Scaffold(
        body: Center(child: Text('Course not found.')),
      );
    }

    final color = Color(course.colorValue);
    final enrollment = state.enrollmentFor(course.id);
    final enrolled = enrollment != null;
    final isOwner = course.instructorId == state.currentUser?.id;
    final progress = enrollment?.progress(course.lessons.length) ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _addLesson(context, course),
              icon: const Icon(Icons.add),
              label: const Text('Add lesson'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(course.category)),
                    Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(course.instructorName),
                    ),
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 16),
                      label: Text('${course.totalMinutes} min'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.group, size: 16),
                      label: Text('${state.enrollmentCount(course.id)} '
                          'enrolled'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                if (enrolled) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).round()}% complete'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => state.unenroll(course.id),
                    icon: const Icon(Icons.logout),
                    label: const Text('Unenroll'),
                  ),
                ] else if (!isOwner) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      await state.enroll(course);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Enrolled in ${course.title}'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_task),
                    label: const Text('Enroll now'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lessons (${course.lessons.length})',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (course.lessons.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No lessons yet.')),
            ),
          for (var i = 0; i < course.lessons.length; i++)
            _LessonTile(
              course: course,
              lesson: course.lessons[i],
              index: i,
              enrolled: enrolled,
              completed: enrollment?.completedLessonIds
                      .contains(course.lessons[i].id) ??
                  false,
            ),
          const SizedBox(height: 24),
          _QuizSection(
            course: course,
            enrolled: enrolled,
            isOwner: isOwner,
            bestScore: enrollment?.quizScore,
          ),
        ],
      ),
    );
  }

  Future<void> _addLesson(BuildContext context, Course course) async {
    final state = context.read<AppState>();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '10');
    var type = LessonType.text;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add lesson'),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    final needsUrl = type != LessonType.text;
    if (result == true &&
        titleCtrl.text.trim().isNotEmpty &&
        (!needsUrl || urlCtrl.text.trim().isNotEmpty)) {
      await state.addLesson(
        course,
        Lesson(
          title: titleCtrl.text.trim(),
          type: type,
          content: contentCtrl.text.trim(),
          url: urlCtrl.text.trim(),
          durationMinutes: int.tryParse(durationCtrl.text.trim()) ?? 10,
        ),
      );
    }
  }
}

class _LessonTile extends StatelessWidget {
  final Course course;
  final Lesson lesson;
  final int index;
  final bool enrolled;
  final bool completed;

  const _LessonTile({
    required this.course,
    required this.lesson,
    required this.index,
    required this.enrolled,
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
}

class _QuizSection extends StatelessWidget {
  final Course course;
  final bool enrolled;
  final bool isOwner;
  final double? bestScore;

  const _QuizSection({
    required this.course,
    required this.enrolled,
    required this.isOwner,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz),
            const SizedBox(width: 8),
            Text(
              'Quiz (${course.quiz.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!course.hasQuiz)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isOwner
                    ? 'No quiz yet. Add questions so students can test '
                        'their knowledge.'
                    : 'No quiz has been added to this course yet.',
              ),
            ),
          )
        else ...[
          if (isOwner)
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < course.quiz.length; i++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(course.quiz[i].prompt),
                      subtitle: Text(
                        'Answer: ${course.quiz[i].options[course.quiz[i].correctIndex]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.deleteQuizQuestion(
                          course,
                          course.quiz[i].id,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (enrolled)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bestScore == null
                          ? '${course.quiz.length} questions · pass mark '
                              '${AppState.quizPassMark.round()}%'
                          : 'Best score: ${bestScore!.round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              QuizScreen(courseId: course.id),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        bestScore == null ? 'Take quiz' : 'Retake quiz',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Enroll to take the quiz.'),
              ),
            ),
        ],
        if (isOwner) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _addQuestion(context, course),
            icon: const Icon(Icons.add),
            label: const Text('Add question'),
          ),
        ],
      ],
    );
  }

  Future<void> _addQuestion(BuildContext context, Course course) async {
    final state = context.read<AppState>();
    final promptCtrl = TextEditingController();
    final optionCtrls =
        List.generate(4, (_) => TextEditingController());
    var correct = 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Question'),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Options (select the correct one):'),
                ),
                RadioGroup<int>(
                  groupValue: correct,
                  onChanged: (v) => setDialogState(() => correct = v!),
                  child: Column(
                    children: [
                      for (var i = 0; i < optionCtrls.length; i++)
                        Row(
                          children: [
                            Radio<int>(value: i),
                            Expanded(
                              child: TextField(
                                controller: optionCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Option ${i + 1}',
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    final options =
        optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (ok == true &&
        promptCtrl.text.trim().isNotEmpty &&
        options.length >= 2 &&
        optionCtrls[correct].text.trim().isNotEmpty) {
      await state.addQuizQuestion(
        course,
        QuizQuestion(
          prompt: promptCtrl.text.trim(),
          options: options,
          correctIndex:
              options.indexOf(optionCtrls[correct].text.trim()),
        ),
      );
    }
  }
}
