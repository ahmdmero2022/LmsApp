import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../utils/certificate_export.dart';

/// Full-screen certificate shown once a student completes every lesson in a
/// course. Offers a "Print / Save as PDF" action on the web.
class CertificateScreen extends StatelessWidget {
  final String courseId;
  const CertificateScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final course = state.courseById(courseId);
    final enrollment = state.enrollmentFor(courseId);
    final user = state.currentUser;

    if (course == null || enrollment == null || user == null) {
      return const Scaffold(body: Center(child: Text('Certificate not found.')));
    }
    if (!enrollment.isCompleted(course.lessons.length)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificate')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Complete all lessons in this course to unlock your certificate.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final date = enrollment.completedAt ?? DateTime.now();
    final dateText = DateFormat.yMMMMd().format(date);

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _CertificateCard(
                studentName: user.name,
                courseTitle: course.title,
                instructorName: course.instructorName,
                dateText: dateText,
              ),
              const SizedBox(height: 20),
              if (canExportCertificate)
                FilledButton.icon(
                  onPressed: () => exportCertificate(
                    studentName: user.name,
                    courseTitle: course.title,
                    instructorName: course.instructorName,
                    dateText: dateText,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Print / Save as PDF'),
                )
              else
                Text(
                  'Printing is available on the web app.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final String studentName;
  final String courseTitle;
  final String instructorName;
  final String dateText;

  const _CertificateCard({
    required this.studentName,
    required this.courseTitle,
    required this.instructorName,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.primary, width: 2.5),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                ),
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              'CERTIFICATE OF COMPLETION',
              style: TextStyle(
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This certifies that',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              studentName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'has successfully completed',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              courseTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SignatureLine(label: 'Instructor', value: instructorName),
                _SignatureLine(label: 'Date', value: dateText),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureLine extends StatelessWidget {
  final String label;
  final String value;
  const _SignatureLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(width: 130, height: 1.4, color: scheme.outlineVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
