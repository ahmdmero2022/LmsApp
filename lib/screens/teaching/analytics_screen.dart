import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/analytics.dart';
import '../../state/app_state.dart';
import '../catalog/course_detail_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final courses = state.myCourses;
    final overview = state.myTeachingStats();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: courses.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _OverviewGrid(stats: overview),
                const SizedBox(height: 28),
                Text(
                  'By course',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final course in courses)
                  _CourseStatsCard(stats: state.statsForCourse(course)),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, size: 72, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          const Text('No analytics yet.'),
          const SizedBox(height: 4),
          Text(
            'Create a course to start tracking engagement.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final InstructorStats stats;
  const _OverviewGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Metric>[
      _Metric(Icons.menu_book_outlined, 'Courses', '${stats.totalCourses}'),
      _Metric(Icons.groups_outlined, 'Students', '${stats.uniqueStudents}'),
      _Metric(Icons.how_to_reg_outlined, 'Enrollments',
          '${stats.totalEnrollments}'),
      _Metric(Icons.workspace_premium_outlined, 'Completions',
          '${stats.totalCompletions}'),
      _Metric(Icons.percent_outlined, 'Completion rate',
          '${(stats.overallCompletionRate * 100).round()}%'),
      _Metric(
        Icons.star_outline,
        'Avg rating',
        stats.avgRating == null ? '—' : stats.avgRating!.toStringAsFixed(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 420
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [for (final t in tiles) _MetricCard(metric: t)],
        );
      },
    );
  }
}

class _Metric {
  final IconData icon;
  final String label;
  final String value;
  const _Metric(this.icon, this.label, this.value);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(metric.icon, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metric.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseStatsCard extends StatelessWidget {
  final CourseStats stats;
  const _CourseStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final course = stats.course;
    final color = Color(course.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(courseId: course.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (stats.avgRating != null) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${stats.avgRating!.toStringAsFixed(1)} '
                      '(${stats.reviewCount})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(
                    label: 'Enrolled',
                    value: '${stats.enrollments}',
                  ),
                  _Stat(
                    label: 'Completed',
                    value: '${stats.completions}',
                  ),
                  _Stat(
                    label: 'Quiz avg',
                    value: stats.avgQuizScore == null
                        ? '—'
                        : '${stats.avgQuizScore!.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Completion',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(stats.completionRate * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stats.completionRate,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
