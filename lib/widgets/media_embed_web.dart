import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registered = {};

/// Converts common YouTube share URLs to their embeddable form so they can be
/// shown inside an `<iframe>`. Other URLs are returned unchanged.
String _resolveVideoUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url;
  final host = uri.host.toLowerCase();
  if (host.contains('youtube.com')) {
    final id = uri.queryParameters['v'];
    if (id != null && id.isNotEmpty) {
      return 'https://www.youtube.com/embed/$id';
    }
    if (uri.pathSegments.contains('embed')) return url;
  }
  if (host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return 'https://www.youtube.com/embed/${uri.pathSegments.first}';
  }
  return url;
}

Widget buildMediaEmbed({
  required String url,
  required bool isVideo,
  double height = 240,
}) {
  final src = isVideo ? _resolveVideoUrl(url) : url;
  final viewType = 'media-embed-${src.hashCode}';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = src
        ..allow = 'autoplay; fullscreen; picture-in-picture'
        ..allowFullscreen = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(
      height: height,
      child: HtmlElementView(viewType: viewType),
    ),
  );
}
