import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../admin/admin_screen.dart';
import '../investors/investor_directory_screen.dart';
import '../jobs/post_job_screen.dart';
import '../market/create_listing_screen.dart';
import '../market/market_screen.dart';
import '../payments/payments_screen.dart';
import '../transport/fleet_screen.dart';
import '../transport/transport_booking_screen.dart';
import '../widgets/common.dart';
import 'dashboard_parts.dart';

/// Single entry point that renders the right dashboard for the user's role.
class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<SessionController>().refreshUser();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              DashboardHeader(user: user),
              const SizedBox(height: 18),
              if (user.isPending) ...[
                const InfoBanner(
                  icon: Icons.hourglass_top,
                  message:
                      'Your account is awaiting verification by the BLOB team. '
                      'Some features stay locked until approval.',
                  color: AppColors.warning,
                  background: AppColors.pendingSoft,
                ),
                const SizedBox(height: 18),
              ],
              ..._bodyFor(context, user),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bodyFor(BuildContext context, AppUser user) {
    return switch (user.role) {
      UserRole.landowner => _landowner(context, user),
      UserRole.buyer => _buyer(context, user),
      UserRole.laborer => _laborer(context, user),
      UserRole.broker => _broker(context, user),
      UserRole.transport => _transport(context, user),
      UserRole.foreignInvestor => _investor(context, user),
      UserRole.globalExporter => _exporter(context, user),
      UserRole.admin => _admin(context, user),
    };
  }

  // ---------------- Landowner ----------------

  List<Widget> _landowner(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final myListings = market.listingsByOwner(user.id);
    final myJobs = market.jobsByPoster(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.add_box_outlined,
            label: 'Sell Crops',
            onTap: () => _push(context, const CreateListingScreen()),
          ),
          ActionTile(
            icon: Icons.groups_outlined,
            label: 'Hire Labour',
            onTap: () => _push(context, const PostJobScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Transport',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
          ActionTile(
            icon: Icons.trending_up,
            label: 'Investors',
            onTap: () => _push(context, const InvestorDirectoryScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Listings',
        actionLabel: myListings.isEmpty ? null : 'Add new',
        onAction: () => _push(context, const CreateListingScreen()),
      ),
      if (myListings.isEmpty)
        EmptyCard(
          icon: Icons.grass,
          message: 'You have not listed any crops yet.',
          actionLabel: 'List your first crop',
          onAction: () => _push(context, const CreateListingScreen()),
        )
      else
        ...myListings.take(4).map((l) => ListingCard(listing: l)),
      const SizedBox(height: 22),
      const SectionHeader('My Job Posts'),
      if (myJobs.isEmpty)
        EmptyCard(
          icon: Icons.work_outline,
          message: 'No jobs posted. Your first 2 posts are free.',
          actionLabel: 'Post a job',
          onAction: () => _push(context, const PostJobScreen()),
        )
      else
        ...myJobs.take(3).map((j) => JobCard(job: j)),
    ];
  }

  // ---------------- Buyer ----------------

  List<Widget> _buyer(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fromFarmers = market.listingsFor(ListingChannel.toBuyers);
    final myResale = market.listingsByOwner(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.storefront_outlined,
            label: 'Buy Crops',
            onTap: () => _push(context, const MarketScreen()),
          ),
          ActionTile(
            icon: Icons.sell_outlined,
            label: 'Sell to Exporters',
            onTap: () => _push(
              context,
              const CreateListingScreen(channel: ListingChannel.toExporters),
            ),
          ),
          ActionTile(
            icon: Icons.groups_outlined,
            label: 'Hire Labour',
            onTap: () => _push(context, const PostJobScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Transport',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'Fresh from Farmers',
        actionLabel: 'View all',
        onAction: () => _push(context, const MarketScreen()),
      ),
      if (fromFarmers.isEmpty)
        const EmptyCard(
          icon: Icons.storefront_outlined,
          message: 'No crops available right now. Check back soon.',
        )
      else
        ...fromFarmers.take(4).map((l) => ListingCard(listing: l, showBuy: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Export Listings'),
      if (myResale.isEmpty)
        EmptyCard(
          icon: Icons.public,
          message: 'Resell your purchased stock to global exporters.',
          actionLabel: 'Create export listing',
          onAction: () => _push(
            context,
            const CreateListingScreen(channel: ListingChannel.toExporters),
          ),
        )
      else
        ...myResale.take(3).map((l) => ListingCard(listing: l)),
    ];
  }

  // ---------------- Laborer ----------------

  List<Widget> _laborer(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final openJobs = market.openJobs();
    final myApps = market.applicationsByLaborer(user.id);

    return [
      WorkTypeBanner(type: user.laborerType ?? LaborerType.singleWorker),
      const SizedBox(height: 20),
      const SectionHeader('Work Available Near You'),
      if (openJobs.isEmpty)
        const EmptyCard(
          icon: Icons.work_off_outlined,
          message: 'No open jobs right now. We will show new work here.',
        )
      else
        ...openJobs.take(4).map((j) => JobCard(job: j, showApply: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Applications'),
      if (myApps.isEmpty)
        const EmptyCard(
          icon: Icons.assignment_outlined,
          message: 'You have not applied to any job yet.',
        )
      else
        ...myApps.take(4).map((a) => ApplicationCard(application: a)),
    ];
  }

  // ---------------- Broker ----------------

  List<Widget> _broker(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final openDeals = market.listingsFor(ListingChannel.toBuyers);

    return [
      CommissionSummary(
        earnedPaise: market.commissionEarnedPaise(user.id),
        pendingPaise: market.pendingIncomingPaise(user.id),
      ),
      const SizedBox(height: 20),
      const SectionHeader('Deals You Can Facilitate'),
      if (openDeals.isEmpty)
        const EmptyCard(
          icon: Icons.handshake_outlined,
          message: 'No active listings to broker at the moment.',
        )
      else
        ...openDeals.take(5).map((l) => ListingCard(listing: l, brokerMode: true)),
    ];
  }

  // ---------------- Transport ----------------

  List<Widget> _transport(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final fleet = market.vehiclesByOwner(user.id);
    final jobs = market.bookingsForUser(user.id);

    return [
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.add_road,
            label: 'Add Vehicle',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.inventory_2_outlined,
            label: 'Goods Jobs',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.airline_seat_recline_normal,
            label: 'Passenger',
            onTap: () => _push(context, const FleetScreen()),
          ),
          ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Earnings',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 22),
      SectionHeader(
        'My Fleet',
        actionLabel: 'Manage',
        onAction: () => _push(context, const FleetScreen()),
      ),
      if (fleet.isEmpty)
        EmptyCard(
          icon: Icons.local_shipping_outlined,
          message: 'Add your first vehicle to start receiving bookings.',
          actionLabel: 'Add vehicle',
          onAction: () => _push(context, const FleetScreen()),
        )
      else
        ...fleet.take(4).map((v) => VehicleCard(vehicle: v)),
      const SizedBox(height: 22),
      const SectionHeader('Incoming Bookings'),
      if (jobs.isEmpty)
        const EmptyCard(
          icon: Icons.event_note_outlined,
          message: 'No bookings yet.',
        )
      else
        ...jobs.take(4).map((b) => BookingCard(booking: b, providerView: true)),
    ];
  }

  // ---------------- Foreign Investor ----------------

  List<Widget> _investor(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final projects = market.listingsFor(ListingChannel.toBuyers);
    final myInvestments =
        market.investments.where((i) => i.investorId == user.id).toList();

    return [
      const InfoBanner(
        icon: Icons.currency_rupee,
        message:
            'All investments are made and settled in Indian Rupees (INR) only.',
      ),
      const SizedBox(height: 20),
      const SectionHeader('Projects Open for Investment'),
      if (projects.isEmpty)
        const EmptyCard(
          icon: Icons.trending_up,
          message: 'No projects available for investment right now.',
        )
      else
        ...projects
            .take(5)
            .map((l) => ListingCard(listing: l, investorMode: true)),
      const SizedBox(height: 22),
      const SectionHeader('My Investments'),
      if (myInvestments.isEmpty)
        const EmptyCard(
          icon: Icons.savings_outlined,
          message: 'You have not invested in any project yet.',
        )
      else
        ...myInvestments.map((i) => InvestmentCard(investment: i)),
    ];
  }

  // ---------------- Global Exporter ----------------

  List<Widget> _exporter(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final exportStock = market.listingsFor(ListingChannel.toExporters);

    return [
      ExporterBanner(user: user),
      const SizedBox(height: 20),
      QuickActionsGrid(
        actions: [
          ActionTile(
            icon: Icons.inventory_2_outlined,
            label: 'Export Stock',
            onTap: () => _push(context, const MarketScreen()),
          ),
          ActionTile(
            icon: Icons.local_shipping_outlined,
            label: 'Book Freight',
            onTap: () => _push(context, const TransportBookingScreen()),
          ),
          ActionTile(
            icon: Icons.receipt_long_outlined,
            label: 'Payments',
            onTap: () => _push(context, const PaymentsScreen()),
          ),
          ActionTile(
            icon: Icons.flight_takeoff,
            label: 'Expedite',
            onTap: () => showSnack(
              context,
              'Priority shipping requested for your next order.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const SectionHeader('Export-Ready Stock'),
      if (exportStock.isEmpty)
        const EmptyCard(
          icon: Icons.public_off,
          message: 'No export-ready listings at the moment.',
        )
      else
        ...exportStock.map((l) => ListingCard(listing: l, showBuy: true)),
    ];
  }

  // ---------------- Admin ----------------

  List<Widget> _admin(BuildContext context, AppUser user) {
    final market = context.watch<MarketplaceController>();
    final pending = market.pendingApprovals();

    return [
      AdminSummary(
        totalUsers: market.users.length,
        pendingCount: pending.length,
        listingCount: market.listings.length,
        jobCount: market.jobs.length,
      ),
      const SizedBox(height: 20),
      SectionHeader(
        'Awaiting Verification',
        actionLabel: pending.isEmpty ? null : 'Review all',
        onAction: () => _push(context, const AdminScreen()),
      ),
      if (pending.isEmpty)
        const EmptyCard(
          icon: Icons.verified_outlined,
          message: 'No accounts awaiting approval.',
        )
      else
        ...pending.take(4).map((u) => PendingUserCard(pendingUser: u)),
    ];
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
