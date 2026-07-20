import 'package:flutter/material.dart';

/// Non-web fallback: inline embedding is not available, so show a hint.
Widget buildMediaEmbed({
  required String url,
  required bool isVideo,
  double height = 240,
}) {
  return Container(
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVideo ? Icons.play_circle_outline : Icons.picture_as_pdf),
          const SizedBox(height: 8),
          Text(
            isVideo
                ? 'Video preview is available on the web app.'
                : 'PDF preview is available on the web app.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
