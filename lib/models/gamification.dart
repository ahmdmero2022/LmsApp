import 'course.dart';
import 'enrollment.dart';
import 'review.dart';

/// Point awards per achievement type.
const int kPointsPerLesson = 10;
const int kPointsPerCourse = 50;
const int kPointsPerQuizPass = 20;
const int kPointsPerReview = 5;

/// Every badge a learner can unlock.
enum BadgeId {
  firstLesson,
  quizPassed,
  perfectScore,
  firstCourse,
  scholar,
  reviewer,
  streak3,
  streak7,
}

class BadgeDef {
  final BadgeId id;
  final String title;
  final String description;
  const BadgeDef(this.id, this.title, this.description);
}

/// Metadata for every badge, in display order.
const List<BadgeDef> kBadgeCatalog = [
  BadgeDef(BadgeId.firstLesson, 'First Steps', 'Complete your first lesson.'),
  BadgeDef(BadgeId.quizPassed, 'Quiz Whiz', 'Pass a course quiz.'),
  BadgeDef(BadgeId.perfectScore, 'Perfectionist', 'Score 100% on a quiz.'),
  BadgeDef(BadgeId.firstCourse, 'Graduate', 'Finish an entire course.'),
  BadgeDef(BadgeId.scholar, 'Scholar', 'Finish three courses.'),
  BadgeDef(BadgeId.reviewer, 'Reviewer', 'Leave a course review.'),
  BadgeDef(BadgeId.streak3, 'On Fire', 'Keep a 3-day learning streak.'),
  BadgeDef(BadgeId.streak7, 'Unstoppable', 'Keep a 7-day learning streak.'),
];

BadgeDef badgeDef(BadgeId id) => kBadgeCatalog.firstWhere((b) => b.id == id);

/// A learner's gamification snapshot.
class UserGameStats {
  final int points;
  final int lessonsCompleted;
  final int coursesCompleted;
  final int quizzesPassed;
  final int reviewsWritten;
  final int streak;
  final Set<BadgeId> badges;

  const UserGameStats({
    required this.points,
    required this.lessonsCompleted,
    required this.coursesCompleted,
    required this.quizzesPassed,
    required this.reviewsWritten,
    required this.streak,
    required this.badges,
  });
}

/// One row of the leaderboard.
class LeaderboardEntry {
  final String userId;
  final String name;
  final int points;
  final int coursesCompleted;
  final int streak;
  final int badgeCount;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.points,
    required this.coursesCompleted,
    required this.streak,
    required this.badgeCount,
  });
}

/// Longest run of consecutive days ending today or yesterday. Returns 0 when
/// the most recent activity is older than yesterday (the streak has lapsed).
int computeStreak(Iterable<DateTime> days, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final anchor = DateTime(now.year, now.month, now.day);
  final set = days
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();
  if (set.isEmpty) return 0;

  // The streak may end today or yesterday; otherwise it has lapsed.
  var cursor = anchor;
  if (!set.contains(cursor)) {
    cursor = anchor.subtract(const Duration(days: 1));
    if (!set.contains(cursor)) return 0;
  }
  var count = 0;
  while (set.contains(cursor)) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

/// Computes the gamification snapshot for [userId] from the full data lists.
UserGameStats computeUserGameStats({
  required String userId,
  required List<Course> courses,
  required List<Enrollment> enrollments,
  required List<Review> reviews,
  required Iterable<DateTime> activeDays,
  double passMark = 60,
}) {
  final coursesById = {for (final c in courses) c.id: c};
  final myEnrollments =
      enrollments.where((e) => e.studentId == userId).toList();

  var lessonsCompleted = 0;
  var coursesCompleted = 0;
  var quizzesPassed = 0;
  var hasPerfectScore = false;

  for (final e in myEnrollments) {
    final course = coursesById[e.courseId];
    if (course != null) {
      final validIds = course.lessons.map((l) => l.id).toSet();
      lessonsCompleted +=
          e.completedLessonIds.where(validIds.contains).length;
      if (e.isCompleted(course.lessons.length)) coursesCompleted++;
    }
    final score = e.quizScore;
    if (score != null && score >= passMark) quizzesPassed++;
    if (score != null && score >= 100) hasPerfectScore = true;
  }

  final reviewsWritten = reviews.where((r) => r.studentId == userId).length;
  final streak = computeStreak(activeDays);

  final points = lessonsCompleted * kPointsPerLesson +
      coursesCompleted * kPointsPerCourse +
      quizzesPassed * kPointsPerQuizPass +
      reviewsWritten * kPointsPerReview;

  final badges = <BadgeId>{};
  if (lessonsCompleted >= 1) badges.add(BadgeId.firstLesson);
  if (quizzesPassed >= 1) badges.add(BadgeId.quizPassed);
  if (hasPerfectScore) badges.add(BadgeId.perfectScore);
  if (coursesCompleted >= 1) badges.add(BadgeId.firstCourse);
  if (coursesCompleted >= 3) badges.add(BadgeId.scholar);
  if (reviewsWritten >= 1) badges.add(BadgeId.reviewer);
  if (streak >= 3) badges.add(BadgeId.streak3);
  if (streak >= 7) badges.add(BadgeId.streak7);

  return UserGameStats(
    points: points,
    lessonsCompleted: lessonsCompleted,
    coursesCompleted: coursesCompleted,
    quizzesPassed: quizzesPassed,
    reviewsWritten: reviewsWritten,
    streak: streak,
    badges: badges,
  );
}
