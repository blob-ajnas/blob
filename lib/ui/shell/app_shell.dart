import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../state/session_controller.dart';
import '../admin/admin_screen.dart';
import '../dashboards/role_home.dart';
import '../jobs/jobs_screen.dart';
import '../market/market_screen.dart';
import '../payments/payments_screen.dart';
import '../profile/profile_screen.dart';
import '../property/property_market_screen.dart';
import '../transport/fleet_screen.dart';
import '../transport/transport_booking_screen.dart';

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

  /// Bottom navigation is capped at five items, so tabs are chosen by
  /// capability in priority order: home, the role's primary workspace, then
  /// generic tabs, then profile. Everything that does not fit remains
  /// reachable from the dashboard quick actions.
  static const int _maxTabsBeforeProfile = 4;

  List<NavDestination> _destinationsFor(AppUser user) {
    final role = user.role;
    bool can(Permission p) => user.can(p);

    final tabs = <NavDestination>[
      const NavDestination(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        labelKey: 'home',
        screen: RoleHome(),
      ),
    ];

    // --- Primary workspace for the role ---
    if (role == UserRole.admin) {
      tabs.add(const NavDestination(
        icon: Icons.verified_user_outlined,
        activeIcon: Icons.verified_user,
        labelKey: 'approvals',
        screen: AdminScreen(),
      ));
    } else if (can(Permission.manageFleet) ||
        can(Permission.manageRentals)) {
      tabs.add(NavDestination(
        icon: role == UserRole.vehicleRental
            ? Icons.vpn_key_outlined
            : role == UserRole.taxiService
                ? Icons.local_taxi_outlined
                : Icons.local_shipping_outlined,
        activeIcon: role == UserRole.vehicleRental
            ? Icons.vpn_key
            : role == UserRole.taxiService
                ? Icons.local_taxi
                : Icons.local_shipping,
        labelKey: role == UserRole.vehicleRental ? 'rentals' : 'fleet',
        screen: const FleetScreen(),
      ));
    } else if (role == UserRole.propertyOwner) {
      tabs.add(const NavDestination(
        icon: Icons.home_work_outlined,
        activeIcon: Icons.home_work,
        labelKey: 'property',
        screen: PropertyMarketScreen(),
      ));
    }

    // --- Generic tabs, added while slots remain ---
    void offer(bool allowed, NavDestination destination) {
      if (allowed && tabs.length < _maxTabsBeforeProfile) {
        tabs.add(destination);
      }
    }

    offer(
      can(Permission.browseMarket),
      const NavDestination(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        labelKey: 'market',
        screen: MarketScreen(),
      ),
    );
    offer(
      can(Permission.postJobs) || can(Permission.applyToJobs),
      const NavDestination(
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        labelKey: 'jobs',
        screen: JobsScreen(),
      ),
    );
    offer(
      can(Permission.viewPaymentTracker),
      const NavDestination(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        labelKey: 'payments',
        screen: PaymentsScreen(),
      ),
    );
    offer(
      role != UserRole.propertyOwner &&
          (can(Permission.browseProperty) || can(Permission.listProperty)),
      const NavDestination(
        icon: Icons.home_work_outlined,
        activeIcon: Icons.home_work,
        labelKey: 'property',
        screen: PropertyMarketScreen(),
      ),
    );
    offer(
      can(Permission.bookTaxi),
      const NavDestination(
        icon: Icons.local_taxi_outlined,
        activeIcon: Icons.local_taxi,
        labelKey: 'rides',
        screen: TransportBookingScreen.taxi(),
      ),
    );

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

    final destinations = _destinationsFor(user);
    final safeIndex = _index.clamp(0, destinations.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: destinations.map((d) => d.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
