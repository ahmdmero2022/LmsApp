import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../state/app_state.dart';
import '../../utils/course_images.dart';
import '../learning/certificate_screen.dart';
import 'course_detail/lesson_section.dart';
import 'course_detail/quiz_section.dart';
import 'course_detail/reviews_section.dart';

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
              onPressed: () => showLessonDialog(context, course),
              icon: const Icon(Icons.add),
              label: const Text('Add lesson'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                courseImageUrl(course),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : ColoredBox(color: color.withValues(alpha: 0.12)),
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.28) ?? color,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                  if (enrollment.isCompleted(course.lessons.length)) ...[
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CertificateScreen(courseId: course.id),
                        ),
                      ),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('View certificate'),
                    ),
                    const SizedBox(height: 8),
                  ],
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
            LessonTile(
              course: course,
              lesson: course.lessons[i],
              index: i,
              enrolled: enrolled,
              isOwner: isOwner,
              completed: enrollment?.completedLessonIds
                      .contains(course.lessons[i].id) ??
                  false,
            ),
          const SizedBox(height: 24),
          QuizSection(
            course: course,
            enrolled: enrolled,
            isOwner: isOwner,
            bestScore: enrollment?.quizScore,
          ),
          const SizedBox(height: 24),
          ReviewsSection(
            course: course,
            enrolled: enrolled,
            isOwner: isOwner,
          ),
        ],
      ),
    );
  }
}
