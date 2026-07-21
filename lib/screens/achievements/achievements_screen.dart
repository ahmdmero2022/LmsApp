import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gamification.dart';
import '../../state/app_state.dart';

IconData badgeIcon(BadgeId id) {
  switch (id) {
    case BadgeId.firstLesson:
      return Icons.play_circle_outline;
    case BadgeId.quizPassed:
      return Icons.quiz_outlined;
    case BadgeId.perfectScore:
      return Icons.stars_outlined;
    case BadgeId.firstCourse:
      return Icons.school_outlined;
    case BadgeId.scholar:
      return Icons.workspace_premium_outlined;
    case BadgeId.reviewer:
      return Icons.rate_review_outlined;
    case BadgeId.streak3:
      return Icons.local_fire_department_outlined;
    case BadgeId.streak7:
      return Icons.bolt_outlined;
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.myGameStats();
    final leaders = state.leaderboard();
    final myId = state.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(stats: stats),
          const SizedBox(height: 24),
          Text(
            'Badges',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BadgeGrid(earned: stats.badges),
          const SizedBox(height: 28),
          Text(
            'Leaderboard',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (leaders.isEmpty)
            const Text('No learners yet.')
          else
            for (var i = 0; i < leaders.length; i++)
              _LeaderTile(
                rank: i + 1,
                entry: leaders[i],
                isMe: leaders[i].userId == myId,
              ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final UserGameStats stats;
  const _HeaderCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.points}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Text(
                  'points',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 32),
              Text(
                '${stats.streak}-day',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text('streak', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final Set<BadgeId> earned;
  const _BadgeGrid({required this.earned});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (final def in kBadgeCatalog)
              _BadgeTile(def: def, unlocked: earned.contains(def.id)),
          ],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDef def;
  final bool unlocked;
  const _BadgeTile({required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = unlocked ? scheme.primary : scheme.outlineVariant;
    return Tooltip(
      message: def.description,
      child: Card(
        elevation: 0,
        color: unlocked
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                unlocked ? badgeIcon(def.id) : Icons.lock_outline,
                size: 34,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                def.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: unlocked ? null : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  const _LeaderTile({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };
    return Card(
      elevation: 0,
      color: isMe ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
      child: ListTile(
        leading: SizedBox(
          width: 28,
          child: Center(
            child: Text(
              medal,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(
          isMe ? '${entry.name} (You)' : entry.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${entry.coursesCompleted} completed · '
          '${entry.badgeCount} badges · ${entry.streak}-day streak',
        ),
        trailing: Text(
          '${entry.points} pts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
