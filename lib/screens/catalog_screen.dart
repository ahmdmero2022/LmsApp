import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../state/app_state.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final all = state.courses;
    final categories = <String>{
      'All',
      ...all.map((c) => c.category),
    }.toList();

    final filtered = all.where((c) {
      final matchesQuery = _query.isEmpty ||
          c.title.toLowerCase().contains(_query.toLowerCase()) ||
          c.description.toLowerCase().contains(_query.toLowerCase());
      final matchesCat = _category == 'All' || c.category == _category;
      return matchesQuery && matchesCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search courses...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final cat in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: Text('No courses match your search.')),
            )
          else
            CourseGrid(
              children: [
                for (final course in filtered)
                  _CatalogCard(course: course),
              ],
            ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Course course;
  const _CatalogCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final enrolled = state.isEnrolled(course.id);
    return CourseCard(
      course: course,
      trailing: enrolled
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Enrolled',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: course.id),
        ),
      ),
    );
  }
}
