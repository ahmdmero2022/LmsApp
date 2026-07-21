import '../models/course.dart';

/// Curated HD Unsplash cover images keyed by a topic keyword. Each URL is
/// requested at card-friendly dimensions with auto-format for the web.
const String _base = 'https://images.unsplash.com/photo-';
const String _params = '?auto=format&fit=crop&w=1200&q=80';

const Map<String, String> _topicImages = {
  'mobile': '${_base}1517694712202-14dd9538aa97$_params',
  'code': '${_base}1498050108023-c5249f4df085$_params',
  'backend': '${_base}1544383835-bda2bc66a55d$_params',
  'data': '${_base}1558494949-ef010cbdcc31$_params',
  'design': '${_base}1561070791-2526d30994b5$_params',
  'business': '${_base}1454165804606-c3d57bc86b40$_params',
  'default': '${_base}1503676260728-1c00da094a0b$_params',
};

/// The cover image for [course]: its explicit [Course.imageUrl] when set,
/// otherwise a sensible default chosen from the category/title keywords.
String courseImageUrl(Course course) {
  final explicit = course.imageUrl;
  if (explicit != null && explicit.trim().isNotEmpty) return explicit;
  return defaultCourseImage('${course.category} ${course.title}');
}

/// Picks a default cover image URL from free-text [keywords].
///
/// Matches on word tokens (prefix, not arbitrary substring) so short keywords
/// don't false-match: e.g. "art" must not match "started"/"smart", "api" must
/// not match "capital", "app" must not match "happen".
String defaultCourseImage(String keywords) {
  final tokens = keywords
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);

  bool has(List<String> stems) =>
      tokens.any((t) => stems.any((s) => t.startsWith(s)));

  if (has(['mobile', 'flutter', 'app', 'android', 'ios'])) {
    return _topicImages['mobile']!;
  }
  if (has(['data', 'sql'])) {
    return _topicImages['data']!;
  }
  if (has(['backend', 'server', 'api', 'cloud'])) {
    return _topicImages['backend']!;
  }
  if (has(['design', 'ui', 'ux', 'art'])) {
    return _topicImages['design']!;
  }
  if (has(['web', 'program', 'code', 'coding', 'develop', 'software'])) {
    return _topicImages['code']!;
  }
  if (has(['business', 'market', 'financ'])) {
    return _topicImages['business']!;
  }
  return _topicImages['default']!;
}
