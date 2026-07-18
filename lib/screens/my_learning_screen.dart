import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final enrollments = state.myEnrollments;
    final total = enrollments.length;
    final completed = enrollments.where((e) {
      final c = state.courseById(e.courseId);
      return c != null && e.isCompleted(c.lessons.length);
    }).length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Learning')),
      body: enrollments.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    _StatCard(
                      label: 'Enrolled',
                      value: '$total',
                      icon: Icons.menu_book,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Completed',
                      value: '$completed',
                      icon: Icons.emoji_events,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CourseGrid(
                  children: [
                    for (final e in enrollments)
                      if (state.courseById(e.courseId) != null)
                        CourseCard(
                          course: state.courseById(e.courseId)!,
                          progress: e.progress(
                            state.courseById(e.courseId)!.lessons.length,
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                courseId: e.courseId,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('You are not enrolled in any courses yet.'),
          const SizedBox(height: 4),
          Text(
            'Head to the Catalog to get started.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
