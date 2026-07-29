import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final goods = market
        .vehiclesByOwner(user.id)
        .where((v) => v.category == VehicleCategory.goods)
        .toList();
    final passenger = market
        .vehiclesByOwner(user.id)
        .where((v) => v.category == VehicleCategory.passenger)
        .toList();
    final incoming = market
        .bookingsForUser(user.id)
        .where((b) => b.providerId == user.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add vehicle',
            onPressed: () => _addVehicleSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SectionHeader('Goods Vehicles'),
            if (goods.isEmpty)
              EmptyCard(
                icon: Icons.local_shipping_outlined,
                message: 'No goods vehicles added.',
                actionLabel: 'Add goods vehicle',
                onAction: () =>
                    _addVehicleSheet(context, VehicleCategory.goods),
              )
            else
              ...goods.map((v) => VehicleCard(vehicle: v)),
            const SizedBox(height: 20),
            const SectionHeader('Passenger Vehicles'),
            if (passenger.isEmpty)
              EmptyCard(
                icon: Icons.airport_shuttle_outlined,
                message: 'No passenger vehicles added.',
                actionLabel: 'Add passenger vehicle',
                onAction: () =>
                    _addVehicleSheet(context, VehicleCategory.passenger),
              )
            else
              ...passenger.map((v) => VehicleCard(vehicle: v)),
            const SizedBox(height: 20),
            const SectionHeader('Booking Requests'),
            if (incoming.isEmpty)
              const EmptyCard(
                icon: Icons.event_note_outlined,
                message: 'No booking requests yet.',
              )
            else
              ...incoming.map(
                (b) => BookingCard(booking: b, providerView: true),
              ),
          ],
        ),
      ),
    );
  }

  void _addVehicleSheet(BuildContext context, [VehicleCategory? preset]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddVehicleSheet(preset: preset),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  final VehicleCategory? preset;
  const _AddVehicleSheet({this.preset});

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _type = TextEditingController();
  final _reg = TextEditingController();
  final _capacity = TextEditingController();
  final _rate = TextEditingController();
  late VehicleCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.preset ?? VehicleCategory.goods;
  }

  @override
  void dispose() {
    _type.dispose();
    _reg.dispose();
    _capacity.dispose();
    _rate.dispose();
    super.dispose();
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
            const Text(
              'Add Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            SegmentedButton<VehicleCategory>(
              segments: const [
                ButtonSegment(
                  value: VehicleCategory.goods,
                  label: Text('Goods'),
                ),
                ButtonSegment(
                  value: VehicleCategory.passenger,
                  label: Text('Passenger'),
                ),
              ],
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _type,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vehicle model',
                hintText: 'e.g. Tata 407 Mini Truck',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reg,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration number',
                hintText: 'KA 09 C 1234',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      suffixText: _category == VehicleCategory.goods
                          ? 'tonnes'
                          : 'seats',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Rate per km',
                      prefixText: '\u20B9 ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final capacity = double.tryParse(_capacity.text) ?? 0;
                final rate = int.tryParse(_rate.text) ?? 0;
                if (_type.text.trim().isEmpty ||
                    _reg.text.trim().isEmpty ||
                    capacity <= 0 ||
                    rate <= 0) {
                  showSnack(context, 'Fill all fields', error: true);
                  return;
                }
                final user = context.read<SessionController>().user!;
                await context.read<MarketplaceController>().addVehicle(
                      owner: user,
                      category: _category,
                      vehicleType: _type.text.trim(),
                      registrationNumber: _reg.text.trim(),
                      capacityValue: capacity,
                      ratePerKmPaise: rate * 100,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                showSnack(context, 'Vehicle added');
              },
              child: const Text('Add Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
