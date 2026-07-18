import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/lesson.dart';
import '../state/app_state.dart';

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
    final progress =
        enrollment?.progress(course.lessons.length) ?? 0;

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
        ],
      ),
    );
  }

  Future<void> _addLesson(BuildContext context, Course course) async {
    final state = context.read<AppState>();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '10');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add lesson'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
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
    );
    if (result == true && titleCtrl.text.trim().isNotEmpty) {
      await state.addLesson(
        course,
        Lesson(
          title: titleCtrl.text.trim(),
          content: contentCtrl.text.trim(),
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
          child: completed
              ? const Icon(Icons.check)
              : Text('${index + 1}'),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${lesson.durationMinutes} min'),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.content),
          if (enrolled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    state.toggleLessonComplete(course, lesson),
                icon: Icon(
                  completed ? Icons.undo : Icons.check_circle,
                ),
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
}
