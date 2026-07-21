import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/course.dart';
import '../../../models/quiz.dart';
import '../../../state/app_state.dart';
import '../../learning/quiz_screen.dart';

class QuizSection extends StatelessWidget {
  final Course course;
  final bool enrolled;
  final bool isOwner;
  final double? bestScore;

  const QuizSection({
    super.key,
    required this.course,
    required this.enrolled,
    required this.isOwner,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz),
            const SizedBox(width: 8),
            Text(
              'Quiz (${course.quiz.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!course.hasQuiz)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isOwner
                    ? 'No quiz yet. Add questions so students can test '
                        'their knowledge.'
                    : 'No quiz has been added to this course yet.',
              ),
            ),
          )
        else ...[
          if (isOwner)
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < course.quiz.length; i++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(course.quiz[i].prompt),
                      subtitle: Text(
                        'Answer: ${course.quiz[i].options[course.quiz[i].correctIndex]}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit question',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => showQuestionDialog(
                              context,
                              course,
                              existing: course.quiz[i],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete question',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _confirmDeleteQuestion(context, course.quiz[i]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else if (enrolled)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bestScore == null
                          ? '${course.quiz.length} questions · pass mark '
                              '${AppState.quizPassMark.round()}%'
                          : 'Best score: ${bestScore!.round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              QuizScreen(courseId: course.id),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        bestScore == null ? 'Take quiz' : 'Retake quiz',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Enroll to take the quiz.'),
              ),
            ),
        ],
        if (isOwner) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showQuestionDialog(context, course),
            icon: const Icon(Icons.add),
            label: const Text('Add question'),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteQuestion(
    BuildContext context,
    QuizQuestion question,
  ) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete question?'),
        content: Text('This will remove "${question.prompt}" from the quiz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await state.deleteQuizQuestion(course, question.id);
    }
  }
}

/// Shows the create/edit quiz-question dialog. When [existing] is provided the
/// dialog pre-fills its fields and saves via `updateQuizQuestion`.
Future<void> showQuestionDialog(
  BuildContext context,
  Course course, {
  QuizQuestion? existing,
}) async {
  final state = context.read<AppState>();
  final isEdit = existing != null;
  final promptCtrl = TextEditingController(text: existing?.prompt ?? '');
  final optionCtrls = List.generate(
    4,
    (i) => TextEditingController(
      text: (existing != null && i < existing.options.length)
          ? existing.options[i]
          : '',
    ),
  );
  var correct = existing?.correctIndex ?? 0;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(isEdit ? 'Edit question' : 'Add question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Question'),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Options (select the correct one):'),
                ),
                RadioGroup<int>(
                  groupValue: correct,
                  onChanged: (v) => setDialogState(() => correct = v!),
                  child: Column(
                    children: [
                      for (var i = 0; i < optionCtrls.length; i++)
                        Row(
                          children: [
                            Radio<int>(value: i),
                            Expanded(
                              child: TextField(
                                controller: optionCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Option ${i + 1}',
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

  final options =
      optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
  if (ok == true &&
      promptCtrl.text.trim().isNotEmpty &&
      options.length >= 2 &&
      optionCtrls[correct].text.trim().isNotEmpty) {
    final question = QuizQuestion(
      id: existing?.id,
      prompt: promptCtrl.text.trim(),
      options: options,
      correctIndex: options.indexOf(optionCtrls[correct].text.trim()),
    );
    if (isEdit) {
      await state.updateQuizQuestion(course, question);
    } else {
      await state.addQuizQuestion(course, question);
    }
  }
}
