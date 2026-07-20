import 'package:flutter/material.dart';

/// Read-only row of stars for a [rating] (supports halves).
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.amber.shade700;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star
                : rating >= i - 0.5
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: c,
          ),
      ],
    );
  }
}

/// Interactive 1-5 star selector.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            tooltip: '$i star${i == 1 ? '' : 's'}',
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star : Icons.star_border,
              size: size,
              color: Colors.amber.shade700,
            ),
          ),
      ],
    );
  }
}
