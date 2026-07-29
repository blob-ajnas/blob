import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../data/models/vehicle.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';

/// Two distinct booking flows: goods vehicles and passenger vehicles.
class TransportBookingScreen extends StatefulWidget {
  const TransportBookingScreen({super.key});

  @override
  State<TransportBookingScreen> createState() =>
      _TransportBookingScreenState();
}

class _TransportBookingScreenState extends State<TransportBookingScreen> {
  VehicleCategory _category = VehicleCategory.goods;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final available = market.availableVehicles(_category);
    final myBookings = market
        .bookingsForUser(user.id)
        .where((b) => b.requesterId == user.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Transport')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SegmentedButton<VehicleCategory>(
                segments: const [
                  ButtonSegment(
                    value: VehicleCategory.goods,
                    label: Text('Goods'),
                    icon: Icon(Icons.local_shipping, size: 18),
                  ),
                  ButtonSegment(
                    value: VehicleCategory.passenger,
                    label: Text('Passenger'),
                    icon: Icon(Icons.airline_seat_recline_normal, size: 18),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (s) => setState(() => _category = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoBanner(
                icon: _category == VehicleCategory.goods
                    ? Icons.inventory_2_outlined
                    : Icons.groups_outlined,
                message: _category.description,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const SectionHeader('Available Vehicles'),
                  if (available.isEmpty)
                    const EmptyCard(
                      icon: Icons.no_transfer,
                      message: 'No vehicles available in this category.',
                    )
                  else
                    ...available.map(
                      (v) => _BookableVehicleCard(vehicle: v),
                    ),
                  const SizedBox(height: 20),
                  const SectionHeader('My Bookings'),
                  if (myBookings.isEmpty)
                    const EmptyCard(
                      icon: Icons.event_busy_outlined,
                      message: 'You have not booked any vehicle yet.',
                    )
                  else
                    ...myBookings.map((b) => BookingCard(booking: b)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookableVehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _BookableVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.category == VehicleCategory.goods
                        ? Icons.local_shipping
                        : Icons.airport_shuttle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleType,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.ownerName} · ${vehicle.capacityLabel}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${Money.format(vehicle.ratePerKmPaise)}/km',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                ),
                onPressed: () => _openBookingSheet(context, vehicle),
                child: const Text('Book this vehicle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBookingSheet(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BookingSheet(vehicle: vehicle),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final Vehicle vehicle;
  const _BookingSheet({required this.vehicle});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _pickup = TextEditingController();
  final _drop = TextEditingController();
  final _distance = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _pickup.dispose();
    _drop.dispose();
    _distance.dispose();
    super.dispose();
  }

  int get _fare {
    final km = double.tryParse(_distance.text) ?? 0;
    return (widget.vehicle.ratePerKmPaise * km).round();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vehicle.vehicleType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.vehicle.capacityLabel} · '
              '${Money.format(widget.vehicle.ratePerKmPaise)} per km',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _pickup,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Pickup location',
                prefixIcon: Icon(Icons.trip_origin, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _drop,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Drop location',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _distance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Approximate distance',
                suffixText: 'km',
                prefixIcon: Icon(Icons.route_outlined),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _when,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (picked != null) setState(() => _when = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 20),
                    const SizedBox(width: 12),
                    const Text('Pickup date'),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM yyyy').format(_when),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            if (_fare > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Estimated fare',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Money.format(_fare),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () async {
                if (_pickup.text.trim().isEmpty ||
                    _drop.text.trim().isEmpty ||
                    _fare <= 0) {
                  showSnack(
                    context,
                    'Fill pickup, drop and distance',
                    error: true,
                  );
                  return;
                }
                final user = context.read<SessionController>().user!;
                await context.read<MarketplaceController>().bookVehicle(
                      vehicle: widget.vehicle,
                      requester: user,
                      pickup: _pickup.text.trim(),
                      drop: _drop.text.trim(),
                      distanceKm: double.parse(_distance.text),
                      scheduledAt: _when,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(context, 'Booking requested');
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
