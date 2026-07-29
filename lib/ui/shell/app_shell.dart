import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../data/models/enums.dart';
import '../../state/session_controller.dart';
import '../admin/admin_screen.dart';
import '../dashboards/role_home.dart';
import '../jobs/jobs_screen.dart';
import '../market/market_screen.dart';
import '../payments/payments_screen.dart';
import '../profile/profile_screen.dart';

class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final Widget screen;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.screen,
  });
}

/// Root shell after login. Tabs are assembled from RBAC permissions,
/// so each role gets a different bottom navigation.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<NavDestination> _destinationsFor(UserRole role) {
    final tabs = <NavDestination>[
      const NavDestination(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        labelKey: 'home',
        screen: RoleHome(),
      ),
    ];

    if (role == UserRole.admin) {
      tabs.add(const NavDestination(
        icon: Icons.verified_user_outlined,
        activeIcon: Icons.verified_user,
        labelKey: 'approvals',
        screen: AdminScreen(),
      ));
    }

    if (Rbac.can(role, Permission.browseMarket)) {
      tabs.add(const NavDestination(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        labelKey: 'market',
        screen: MarketScreen(),
      ));
    }

    if (Rbac.can(role, Permission.postJobs) ||
        Rbac.can(role, Permission.applyToJobs)) {
      tabs.add(const NavDestination(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        labelKey: 'jobs',
        screen: JobsScreen(),
      ));
    }

    if (Rbac.can(role, Permission.viewPaymentTracker)) {
      tabs.add(const NavDestination(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        labelKey: 'payments',
        screen: PaymentsScreen(),
      ));
    }

    tabs.add(const NavDestination(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: 'profile',
      screen: ProfileScreen(),
    ));

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink();

    final destinations = _destinationsFor(user.role);
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        items: destinations
            .map(
              (d) => BottomNavigationBarItem(
                icon: Icon(d.icon),
                activeIcon: Icon(d.activeIcon),
                label: _label(session, d.labelKey),
              ),
            )
            .toList(),
      ),
    );
  }

  String _label(SessionController session, String key) {
    if (key == 'approvals') return 'Approvals';
    return session.t(key);
  }
}
