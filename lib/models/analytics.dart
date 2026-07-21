import 'course.dart';
import 'enrollment.dart';
import 'review.dart';

/// Aggregated teaching metrics for a single course.
class CourseStats {
  final Course course;
  final int enrollments;
  final int completions;

  /// Fraction of enrolled students who finished every lesson (0..1).
  final double completionRate;

  /// Mean lesson-completion progress across enrolled students (0..1).
  final double avgProgress;

  /// Mean best quiz score across students who attempted it, or null.
  final double? avgQuizScore;
  final int quizAttempts;

  /// Mean star rating, or null when there are no reviews.
  final double? avgRating;
  final int reviewCount;

  const CourseStats({
    required this.course,
    required this.enrollments,
    required this.completions,
    required this.completionRate,
    required this.avgProgress,
    required this.avgQuizScore,
    required this.quizAttempts,
    required this.avgRating,
    required this.reviewCount,
  });
}

/// Aggregated metrics across all of an instructor's courses.
class InstructorStats {
  final int totalCourses;
  final int totalEnrollments;
  final int uniqueStudents;
  final int totalCompletions;

  /// Completions divided by enrollments across all courses (0..1).
  final double overallCompletionRate;

  /// Mean star rating across all reviews on the instructor's courses.
  final double? avgRating;

  const InstructorStats({
    required this.totalCourses,
    required this.totalEnrollments,
    required this.uniqueStudents,
    required this.totalCompletions,
    required this.overallCompletionRate,
    required this.avgRating,
  });
}

/// Computes [CourseStats] for [course] from the full lists of [enrollments]
/// and [reviews] (both are filtered to the course internally).
CourseStats computeCourseStats(
  Course course,
  List<Enrollment> enrollments,
  List<Review> reviews,
) {
  final ens = enrollments.where((e) => e.courseId == course.id).toList();
  final total = course.lessons.length;
  final completions = ens.where((e) => e.isCompleted(total)).length;
  final avgProgress = ens.isEmpty
      ? 0.0
      : ens.fold<double>(0, (acc, e) => acc + e.progress(total)) / ens.length;
  final quizScores =
      ens.map((e) => e.quizScore).whereType<double>().toList(growable: false);
  final avgQuizScore = quizScores.isEmpty
      ? null
      : quizScores.reduce((a, b) => a + b) / quizScores.length;
  final courseReviews = reviews.where((r) => r.courseId == course.id).toList();
  final avgRating = courseReviews.isEmpty
      ? null
      : courseReviews.fold<int>(0, (acc, r) => acc + r.rating) /
          courseReviews.length;
  return CourseStats(
    course: course,
    enrollments: ens.length,
    completions: completions,
    completionRate: ens.isEmpty ? 0 : completions / ens.length,
    avgProgress: avgProgress,
    avgQuizScore: avgQuizScore,
    quizAttempts: quizScores.length,
    avgRating: avgRating,
    reviewCount: courseReviews.length,
  );
}

/// Computes [InstructorStats] across [courses] from the full lists of
/// [enrollments] and [reviews].
InstructorStats computeInstructorStats(
  List<Course> courses,
  List<Enrollment> enrollments,
  List<Review> reviews,
) {
  final courseIds = courses.map((c) => c.id).toSet();
  final ens =
      enrollments.where((e) => courseIds.contains(e.courseId)).toList();
  var completions = 0;
  for (final c in courses) {
    final total = c.lessons.length;
    completions +=
        ens.where((e) => e.courseId == c.id && e.isCompleted(total)).length;
  }
  final myReviews =
      reviews.where((r) => courseIds.contains(r.courseId)).toList();
  final avgRating = myReviews.isEmpty
      ? null
      : myReviews.fold<int>(0, (acc, r) => acc + r.rating) / myReviews.length;
  return InstructorStats(
    totalCourses: courses.length,
    totalEnrollments: ens.length,
    uniqueStudents: ens.map((e) => e.studentId).toSet().length,
    totalCompletions: completions,
    overallCompletionRate: ens.isEmpty ? 0 : completions / ens.length,
    avgRating: avgRating,
  );
}
