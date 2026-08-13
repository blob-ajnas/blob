import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/learning.dart';
import '../../state/session_controller.dart';
import '../edu/edu_shell.dart';
import 'app_shell.dart';

/// Decides which of the two apps a signed-in user sees, and gives that app its
/// own theme.
///
/// BLOB ships two separate products behind one login:
///
///  * **Job Seeker** → [AppShell], the agri marketplace and jobs board (green).
///  * **Student**    → [EduShell], education, competition and progress (blue).
///
/// The two never interleave. There is no tab, link or shortcut from one into
/// the other; the only crossing point is "Switch account type" in Profile,
/// which rewrites the account's category and rebuilds from this widget. That
/// keeps the boundary in exactly one place instead of scattering
/// `if (isStudent)` checks through every screen.
class TrackRouter extends StatelessWidget {
  const TrackRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    final track = AppTrack.of(user);

    // The palette is re-pointed before the subtree builds, so descendants
    // reading AppColors.* (including inside const constructors) pick up the
    // right brand colour for this track. See AppColors.applyPalette.
    AppColors.applyPalette(track.palette);

    return Theme(
      data: track.theme,
      child: track.isEducation ? const EduShell() : const AppShell(),
    );
  }
}

/// The two products, and everything that differs between them.
enum AppTrack {
  /// Agri marketplace: crops, jobs, transport, property, payments.
  marketplace,

  /// Education: lessons, quizzes, games, competition, progress.
  education;

  /// Education is driven by the account category chosen at signup, not by the
  /// role, so an existing marketplace account that switches to Student moves
  /// tracks without needing a new login.
  static AppTrack of(AppUser user) =>
      user.category == UserCategory.student ? education : marketplace;

  bool get isEducation => this == AppTrack.education;

  AppPalette get palette =>
      isEducation ? const EduPalette() : const AgriPalette();

  ThemeData get theme => isEducation ? AppTheme.edu : AppTheme.agri;

  String get label => isEducation ? 'Student' : 'Job Seeker';
}
