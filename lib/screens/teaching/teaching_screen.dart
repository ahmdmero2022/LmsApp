import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../state/app_state.dart';
import '../../widgets/course_card.dart';
import '../catalog/course_detail_screen.dart';

const _courseColors = <int>[
  0xFF1565C0,
  0xFF2E7D32,
  0xFF6A1B9A,
  0xFFC62828,
  0xFFEF6C00,
  0xFF00838F,
];

class TeachingScreen extends StatelessWidget {
  const TeachingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myCourses = state.myCourses;

    return Scaffold(
      appBar: AppBar(title: const Text('Teaching')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCourse(context),
        icon: const Icon(Icons.add),
        label: const Text('New course'),
      ),
      body: myCourses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.co_present_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('You have not created any courses yet.'),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "New course" to publish your first one.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CourseGrid(
                  children: [
                    for (final course in myCourses)
                      CourseCard(
                        course: course,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white),
                          onSelected: (v) {
                            if (v == 'delete') {
                              _confirmDelete(context, course);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CourseDetailScreen(courseId: course.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          'This will remove "${course.title}" and all its enrollments.',
        ),
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
      await state.deleteCourse(course.id);
    }
  }

  Future<void> _createCourse(BuildContext context) async {
    final state = context.read<AppState>();
    final user = state.currentUser!;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    int color = _courseColors.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create course'),
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
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Accent color',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in _courseColors)
                      GestureDetector(
                        onTap: () => setDialogState(() => color = c),
                        child: CircleAvatar(
                          backgroundColor: Color(c),
                          child: color == c
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                  ],
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
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && titleCtrl.text.trim().isNotEmpty) {
      await state.createCourse(
        Course(
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          category: categoryCtrl.text.trim().isEmpty
              ? 'General'
              : categoryCtrl.text.trim(),
          instructorId: user.id,
          instructorName: user.name,
          colorValue: color,
        ),
      );
    }
  }
}
