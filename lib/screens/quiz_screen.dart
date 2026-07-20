import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/quiz.dart';
import '../state/app_state.dart';

/// Lets an enrolled student answer a course's multiple-choice quiz, then grades
/// it and records the score.
class QuizScreen extends StatefulWidget {
  final String courseId;
  const QuizScreen({super.key, required this.courseId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<String, int> _answers = {};
  bool _submitted = false;
  int _correct = 0;

  Future<void> _submit(Course course) async {
    var correct = 0;
    for (final q in course.quiz) {
      if (_answers[q.id] == q.correctIndex) correct++;
    }
    setState(() {
      _submitted = true;
      _correct = correct;
    });
    await context.read<AppState>().submitQuiz(course, correct, course.quiz.length);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final course = state.courseById(widget.courseId);
    if (course == null || !course.hasQuiz) {
      return const Scaffold(body: Center(child: Text('Quiz not found.')));
    }

    final total = course.quiz.length;
    final allAnswered = _answers.length == total;
    final pct = total == 0 ? 0 : (_correct / total * 100).round();
    final passed = pct >= AppState.quizPassMark;

    return Scaffold(
      appBar: AppBar(title: Text('${course.title} — Quiz')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_submitted)
            Card(
              color: passed
                  ? Colors.green.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      passed ? Icons.emoji_events : Icons.replay,
                      size: 40,
                      color: passed ? Colors.green : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            passed ? 'Passed! 🎯' : 'Keep practising',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('You scored $pct% ($_correct/$total correct).'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_submitted) const SizedBox(height: 16),
          for (var i = 0; i < course.quiz.length; i++)
            _QuestionCard(
              index: i,
              question: course.quiz[i],
              selected: _answers[course.quiz[i].id],
              submitted: _submitted,
              onSelect: _submitted
                  ? null
                  : (v) => setState(() => _answers[course.quiz[i].id] = v),
            ),
          const SizedBox(height: 12),
          if (!_submitted)
            FilledButton.icon(
              onPressed: allAnswered ? () => _submit(course) : null,
              icon: const Icon(Icons.check),
              label: Text(
                allAnswered
                    ? 'Submit answers'
                    : 'Answer all questions (${_answers.length}/$total)',
              ),
            )
          else ...[
            FilledButton.tonalIcon(
              onPressed: () => setState(() {
                _answers.clear();
                _submitted = false;
                _correct = 0;
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Retake quiz'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to course'),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final int? selected;
  final bool submitted;
  final ValueChanged<int>? onSelect;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.submitted,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}. ${question.prompt}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: selected,
              onChanged: (v) {
                if (onSelect != null && v != null) onSelect!(v);
              },
              child: Column(
                children: [
                  for (var o = 0; o < question.options.length; o++)
                    _buildOption(context, o),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, int o) {
    final isCorrect = o == question.correctIndex;
    final isChosen = o == selected;
    Color? tileColor;
    if (submitted) {
      if (isCorrect) {
        tileColor = Colors.green.withValues(alpha: 0.18);
      } else if (isChosen) {
        tileColor = Theme.of(context).colorScheme.errorContainer;
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<int>(
        value: o,
        enabled: !submitted,
        title: Text(question.options[o]),
        secondary: submitted && isCorrect
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        dense: true,
      ),
    );
  }
}
