/// Bundles everything the three daily task screens need, so one set of task
/// mechanics can serve two completely different subject areas.
///
/// The video, quiz and game screens take a pack and render whatever it holds.
/// That keeps the education track's content strictly education (no crops,
/// mandis, commission or labour) without duplicating ~700 lines of game code,
/// and means adding a third track later is a data change, not a UI change.
library;

import 'edu_content.dart';
import 'learning_content.dart';

// Task screens take a pack and nothing else, so they get the content shapes
// from here rather than reaching into either track's content library.
export 'task_types.dart';

class TaskContentPack {
  /// Today's 15-minute lesson.
  final VideoLesson video;

  /// The ten daily quiz questions.
  final List<QuizQuestion> quiz;

  /// Round data for the three games.
  final List<MathRound> mathRounds;
  final List<TermPair> termPairs;
  final List<OrderRound> orderRounds;

  /// Per-track game titles and framing copy.
  final String mathTitle;
  final String mathSubtitle;
  final String matchTitle;
  final String matchSubtitle;
  final String orderTitle;
  final String orderSubtitle;

  /// Whether maths answers are money. Drives ₹ formatting and Indian digit
  /// grouping — a student solving `18²` should see "324", not "₹324".
  final bool mathAnswersAreMoney;

  /// Framing shown on the quiz and video screens.
  final String quizSubject;

  const TaskContentPack({
    required this.video,
    required this.quiz,
    required this.mathRounds,
    required this.termPairs,
    required this.orderRounds,
    required this.mathTitle,
    required this.mathSubtitle,
    required this.matchTitle,
    required this.matchSubtitle,
    required this.orderTitle,
    required this.orderSubtitle,
    required this.quizSubject,
    this.mathAnswersAreMoney = false,
  });

  /// Education track — school and college subjects.
  static const TaskContentPack education = TaskContentPack(
    video: EduContent.todaysVideo,
    quiz: EduContent.dailyQuiz,
    mathRounds: EduContent.mathRounds,
    termPairs: EduContent.termPairs,
    orderRounds: EduContent.orderRounds,
    mathTitle: 'Quick Maths',
    mathSubtitle: 'Solve exam-style sums against the clock',
    matchTitle: 'Match the Term',
    matchSubtitle: 'Pair academic terms with their meaning',
    orderTitle: 'Put in Order',
    orderSubtitle: 'Sequence steps, values and units correctly',
    quizSubject: 'Science, maths, civics and English',
  );

  /// Job-seeker track — market and trade knowledge.
  static const TaskContentPack marketplace = TaskContentPack(
    video: LearningContent.todaysVideo,
    quiz: LearningContent.dailyQuiz,
    mathRounds: LearningContent.mathRounds,
    termPairs: LearningContent.termPairs,
    orderRounds: LearningContent.orderRounds,
    mathTitle: 'Market Maths',
    mathSubtitle: 'Work out quintal and commission totals',
    matchTitle: 'Match the Term',
    matchSubtitle: 'Pair trading words with their meaning',
    orderTitle: 'Price Order',
    orderSubtitle: 'Sort crop prices from low to high',
    quizSubject: 'Farming and scheme knowledge',
    mathAnswersAreMoney: true,
  );
}
