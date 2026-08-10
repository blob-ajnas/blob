import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/learning_content.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Daily task 2 — play 3 interactive rounds.
///
/// Three distinct mechanics rather than the same game three times: market
/// arithmetic, term matching, and price-order sorting. Each is drawn from
/// content a trader or student actually needs.
class GamesTaskScreen extends StatefulWidget {
  const GamesTaskScreen({super.key});

  @override
  State<GamesTaskScreen> createState() => _GamesTaskScreenState();
}

class _GamesTaskScreenState extends State<GamesTaskScreen> {
  int _roundsDoneToday = 0;

  @override
  void initState() {
    super.initState();
    final userId = context.read<SessionController>().user?.id;
    if (userId != null) {
      _roundsDoneToday =
          context.read<LearningController>().progressFor(userId).gamesPlayed;
    }
  }

  Future<void> _openGame(int index) async {
    final result = await Navigator.of(context).push<({int score, int outOf})>(
      MaterialPageRoute(
        builder: (_) => switch (index) {
          0 => const _MathGame(),
          1 => const _MatchGame(),
          _ => const _SortGame(),
        },
      ),
    );
    if (result == null || !mounted) return;

    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();
    final userId = session.user?.id;
    if (userId == null) return;

    final awarded = await learning.addGameRound(
      userId,
      score: result.score,
      outOf: result.outOf,
    );
    if (!mounted) return;
    setState(() {
      _roundsDoneToday = learning.progressFor(userId).gamesPlayed;
    });
    if (awarded > 0) {
      showSnack(context,
          'All 3 games complete — +$awarded points earned');
    } else {
      showSnack(context,
          'Round saved — ${DailyTaskType.games.target - _roundsDoneToday} to go');
    }
  }

  @override
  Widget build(BuildContext context) {
    const games = [
      (
        title: 'Market Maths',
        subtitle: 'Work out quintal and commission totals',
        icon: Icons.calculate_outlined,
      ),
      (
        title: 'Match the Term',
        subtitle: 'Pair trading words with their meaning',
        icon: Icons.extension_outlined,
      ),
      (
        title: 'Price Order',
        subtitle: 'Sort crop prices from low to high',
        icon: Icons.swap_vert_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Learning games')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_roundsDoneToday of '
                          '${DailyTaskType.games.target} rounds done',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Finish all 3 to earn '
                          '${DailyTaskType.games.points} points',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < games.length; i++) ...[
              _GameCard(
                title: games[i].title,
                subtitle: games[i].subtitle,
                icon: games[i].icon,
                roundNumber: i + 1,
                onTap: () => _openGame(i),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            const InfoBanner(
              icon: Icons.info_outline,
              message: 'You can replay any game, but each day counts a '
                  'maximum of 3 rounds towards your points.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int roundNumber;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.roundNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Game 1

/// Five market-arithmetic questions.
class _MathGame extends StatefulWidget {
  const _MathGame();

  @override
  State<_MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<_MathGame> {
  late final List<({String prompt, int answer, List<int> options})> _rounds;
  int _index = 0;
  int _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _rounds = List.of(LearningContent.mathRounds)..shuffle(Random());
  }

  void _pick(int value) {
    if (_picked != null) return;
    setState(() {
      _picked = value;
      if (value == _rounds[_index].answer) _score++;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_index >= _rounds.length - 1) {
        Navigator.of(context).pop((score: _score, outOf: _rounds.length));
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Market Maths')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GameProgress(
                current: _index + 1,
                total: _rounds.length,
                score: _score,
              ),
              const SizedBox(height: 28),
              Text(
                round.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              for (final option in round.options) ...[
                _OptionButton(
                  label: '\u20B9${_format(option)}',
                  state: _picked == null
                      ? _OptionState.idle
                      : option == round.answer
                          ? _OptionState.correct
                          : option == _picked
                              ? _OptionState.wrong
                              : _OptionState.dimmed,
                  onTap: () => _pick(option),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _format(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    // Indian grouping: last 3, then pairs.
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}

// ---------------------------------------------------------------- Game 2

/// Tap a term, then tap its meaning.
class _MatchGame extends StatefulWidget {
  const _MatchGame();

  @override
  State<_MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<_MatchGame> {
  static const _pairCount = 4;

  late List<({String term, String meaning})> _pairs;
  late List<String> _terms;
  late List<String> _meanings;

  String? _selectedTerm;
  final Set<String> _matched = {};
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    final all = List.of(LearningContent.termPairs)..shuffle(Random());
    _pairs = all.take(_pairCount).toList();
    _terms = _pairs.map((p) => p.term).toList()..shuffle(Random());
    _meanings = _pairs.map((p) => p.meaning).toList()..shuffle(Random());
  }

  void _tapMeaning(String meaning) {
    final term = _selectedTerm;
    if (term == null) {
      showSnack(context, 'Pick a term on the left first');
      return;
    }
    final expected = _pairs.firstWhere((p) => p.term == term).meaning;
    if (expected == meaning) {
      setState(() {
        _matched.add(term);
        _selectedTerm = null;
      });
      if (_matched.length == _pairs.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          Navigator.of(context).pop((
            score: _pairs.length,
            outOf: _pairs.length + _mistakes,
          ));
        });
      }
    } else {
      setState(() {
        _mistakes++;
        _selectedTerm = null;
      });
      showSnack(context, 'Not a match — try again', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match the Term')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _GameProgress(
                current: _matched.length,
                total: _pairs.length,
                score: _matched.length,
                label: 'matched',
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap a term, then tap its meaning',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final term in _terms) ...[
                            _MatchChip(
                              label: term,
                              bold: true,
                              done: _matched.contains(term),
                              selected: _selectedTerm == term,
                              onTap: _matched.contains(term)
                                  ? null
                                  : () =>
                                      setState(() => _selectedTerm = term),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final meaning in _meanings) ...[
                            _MatchChip(
                              label: meaning,
                              done: _pairs.any((p) =>
                                  p.meaning == meaning &&
                                  _matched.contains(p.term)),
                              selected: false,
                              onTap: _pairs.any((p) =>
                                      p.meaning == meaning &&
                                      _matched.contains(p.term))
                                  ? null
                                  : () => _tapMeaning(meaning),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool done;
  final bool bold;
  final VoidCallback? onTap;

  const _MatchChip({
    required this.label,
    required this.selected,
    required this.done,
    this.bold = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.primary
        : selected
            ? AppColors.accentSoft
            : AppColors.surface;
    final fg = done ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Game 3

/// Reorder four prices from lowest to highest.
class _SortGame extends StatefulWidget {
  const _SortGame();

  @override
  State<_SortGame> createState() => _SortGameState();
}

class _SortGameState extends State<_SortGame> {
  late List<({String crop, int price})> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      (crop: 'Sugarcane', price: 340),
      (crop: 'Paddy (Sona Masuri)', price: 2300),
      (crop: 'Turmeric Fingers', price: 8900),
      (crop: 'Arabica Coffee', price: 18500),
    ]..shuffle(Random());
  }

  bool get _isSorted {
    for (var i = 0; i < _items.length - 1; i++) {
      if (_items[i].price > _items[i + 1].price) return false;
    }
    return true;
  }

  void _submit() {
    if (_isSorted) {
      Navigator.of(context).pop((score: _items.length, outOf: _items.length));
    } else {
      var correct = 0;
      final sorted = List.of(_items)
        ..sort((a, b) => a.price.compareTo(b.price));
      for (var i = 0; i < _items.length; i++) {
        if (_items[i].crop == sorted[i].crop) correct++;
      }
      showSnack(context,
          'Not quite — $correct of ${_items.length} in the right place',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price Order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Drag to arrange from lowest to highest price per quintal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _items.removeAt(oldIndex);
                      _items.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (final item in _items)
                      Container(
                        key: ValueKey(item.crop),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator,
                                color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.crop,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Check order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Shared

class _GameProgress extends StatelessWidget {
  final int current;
  final int total;
  final int score;
  final String label;

  const _GameProgress({
    required this.current,
    required this.total,
    required this.score,
    this.label = 'correct',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$score $label',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _OptionState.idle => (AppColors.surface, AppColors.border, AppColors.textPrimary),
      _OptionState.correct => (AppColors.primary, AppColors.primary, Colors.white),
      _OptionState.wrong => (AppColors.dangerSoft, AppColors.danger, AppColors.danger),
      _OptionState.dimmed => (AppColors.background, AppColors.border, AppColors.textSecondary),
    };

    return InkWell(
      onTap: state == _OptionState.idle ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }
}
