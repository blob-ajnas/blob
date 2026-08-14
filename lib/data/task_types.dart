/// Shared shapes for daily-task game content.
///
/// These live in their own file, rather than beside either content library, so
/// both `learning_content.dart` (marketplace) and `edu_content.dart`
/// (education) can depend on them without either depending on the other. An
/// earlier attempt put them in `learning_content.dart`, which made the edu
/// track import marketplace code purely to borrow a type — the exact coupling
/// this refactor exists to remove.
library;

import 'dart:math';

/// One arithmetic round: a prompt, the correct answer, and the choices shown.
/// Answers are whole numbers; any unit belongs in [prompt] (e.g. "= ? (%)")
/// so nothing has to be inferred at render time.
typedef MathRound = ({String prompt, int answer, List<int> options});

/// One term-matching pair.
typedef TermPair = ({String term, String meaning});

/// One sequencing round. [ordered] is the correct sequence; the game shuffles
/// it for presentation.
typedef OrderRound = ({String prompt, List<String> ordered});

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Returns the same question with its options in a random order.
  ///
  /// Every question is authored with the answer first, which keeps the source
  /// readable but would let a learner score 10/10 by tapping A ten times — the
  /// quiz would measure nothing. Shuffling at presentation time keeps authoring
  /// simple and the answer position unguessable.
  QuizQuestion shuffled([Random? random]) {
    final rng = random ?? Random();
    final indices = List<int>.generate(options.length, (i) => i)..shuffle(rng);
    return QuizQuestion(
      question: question,
      options: [for (final i in indices) options[i]],
      correctIndex: indices.indexOf(correctIndex),
      explanation: explanation,
    );
  }
}

class VideoLesson {
  final String id;
  final String title;
  final String presenter;
  final int minutes;
  final String summary;

  const VideoLesson({
    required this.id,
    required this.title,
    required this.presenter,
    required this.minutes,
    required this.summary,
  });
}
