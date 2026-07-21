import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/course.dart';
import '../../../models/review.dart';
import '../../../state/app_state.dart';
import '../../../widgets/star_rating.dart';

class ReviewsSection extends StatelessWidget {
  final Course course;
  final bool enrolled;
  final bool isOwner;

  const ReviewsSection({
    super.key,
    required this.course,
    required this.enrolled,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reviews = state.reviewsForCourse(course.id);
    final avg = state.averageRating(course.id);
    final myReview = state.myReviewFor(course.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.reviews_outlined),
            const SizedBox(width: 8),
            Text(
              'Reviews (${reviews.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (avg != null) ...[
              StarRating(rating: avg, size: 18),
              const SizedBox(width: 6),
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (enrolled && !isOwner) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => showReviewDialog(context, course, myReview),
              icon: Icon(myReview == null ? Icons.rate_review : Icons.edit),
              label: Text(
                myReview == null ? 'Leave a review' : 'Edit your review',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (reviews.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                enrolled
                    ? 'No reviews yet — be the first to review this course.'
                    : 'No reviews yet.',
              ),
            ),
          )
        else
          for (final r in reviews)
            _ReviewTile(
              review: r,
              isMine: r.id == myReview?.id,
            ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  final bool isMine;
  const _ReviewTile({required this.review, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    review.studentName.isNotEmpty
                        ? review.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMine ? '${review.studentName} (you)' : review.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                StarRating(rating: review.rating.toDouble()),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows the create/edit review dialog for the current student. When [existing]
/// is provided the fields are pre-filled.
Future<void> showReviewDialog(
  BuildContext context,
  Course course,
  Review? existing,
) async {
  final state = context.read<AppState>();
  final commentCtrl = TextEditingController(text: existing?.comment ?? '');
  var rating = existing?.rating ?? 0;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Leave a review' : 'Edit your review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your rating'),
            const SizedBox(height: 4),
            StarRatingInput(
              value: rating,
              onChanged: (v) => setDialogState(() => rating = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Share what you thought about this course',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                rating == 0 ? null : () => Navigator.pop(ctx, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );

  if (ok == true && rating > 0) {
    await state.saveReview(
      course,
      rating: rating,
      comment: commentCtrl.text,
    );
  }
}
