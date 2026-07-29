import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/local_db.dart';
import 'data/seed.dart';
import 'state/marketplace_controller.dart';
import 'state/session_controller.dart';
import 'ui/onboarding/welcome_screen.dart';
import 'ui/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.instance.init();
  await Seed.ensure();
  runApp(const BlobApp());
}

class BlobApp extends StatelessWidget {
  const BlobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()..load()),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
      ],
      child: MaterialApp(
        title: 'BLOB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    if (session.isLoggedIn) return const AppShell();
    return const WelcomeScreen();
  }
}
