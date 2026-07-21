/// A single day on which a user was active (completed a lesson, passed a quiz,
/// enrolled, or left a review). One record per user per calendar day powers the
/// learning-streak counter.
class ActivityDay {
  final String userId;

  /// Normalized to midnight (local) so equality is day-granular.
  final DateTime date;

  ActivityDay({required this.userId, required DateTime date})
      : date = DateTime(date.year, date.month, date.day);

  /// Stable key so the same user/day is idempotent.
  String get id => '$userId|${dateKey(date)}';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'date': date.toIso8601String(),
      };

  factory ActivityDay.fromMap(Map<String, dynamic> map) => ActivityDay(
        userId: map['userId'] as String,
        date: DateTime.parse(map['date'] as String),
      );
}
