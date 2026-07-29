import 'enums.dart';

/// vehicles table/collection — owned by transport providers.
class Vehicle {
  final String id;
  final String ownerId;
  final String ownerName;
  final VehicleCategory category;
  final String vehicleType; // Tractor Trailer, Mini Truck, Tempo, Jeep, Bus
  final String registrationNumber;
  final double capacityValue; // tonnes for goods, seats for passenger
  final int ratePerKmPaise;
  final String district;
  final bool available;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.vehicleType,
    required this.registrationNumber,
    required this.capacityValue,
    required this.ratePerKmPaise,
    required this.district,
    this.available = true,
  });

  String get capacityLabel => category == VehicleCategory.goods
      ? '${capacityValue.toStringAsFixed(1)} tonnes'
      : '${capacityValue.toInt()} seats';

  Vehicle copyWith({bool? available}) => Vehicle(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    category: category,
    vehicleType: vehicleType,
    registrationNumber: registrationNumber,
    capacityValue: capacityValue,
    ratePerKmPaise: ratePerKmPaise,
    district: district,
    available: available ?? this.available,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'owner_name': ownerName,
    'category': category.name,
    'vehicle_type': vehicleType,
    'registration_number': registrationNumber,
    'capacity_value': capacityValue,
    'rate_per_km_paise': ratePerKmPaise,
    'district': district,
    'available': available,
  };

  factory Vehicle.fromMap(Map<dynamic, dynamic> m) => Vehicle(
    id: m['id'] as String? ?? '',
    ownerId: m['owner_id'] as String? ?? '',
    ownerName: m['owner_name'] as String? ?? '',
    category: VehicleCategoryX.fromId(m['category'] as String? ?? 'goods'),
    vehicleType: m['vehicle_type'] as String? ?? '',
    registrationNumber: m['registration_number'] as String? ?? '',
    capacityValue: (m['capacity_value'] as num?)?.toDouble() ?? 0,
    ratePerKmPaise: (m['rate_per_km_paise'] as num?)?.toInt() ?? 0,
    district: m['district'] as String? ?? '',
    available: m['available'] as bool? ?? true,
  );
}

/// vehicle_bookings table/collection.
class VehicleBooking {
  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final VehicleCategory category;
  final String requesterId;
  final String requesterName;
  final String providerId;
  final String pickup;
  final String drop;
  final double distanceKm;
  final int farePaise;
  final DateTime scheduledAt;
  final BookingStatus status;
  final DateTime createdAt;

  const VehicleBooking({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.category,
    required this.requesterId,
    required this.requesterName,
    required this.providerId,
    required this.pickup,
    required this.drop,
    required this.distanceKm,
    required this.farePaise,
    required this.scheduledAt,
    required this.createdAt,
    this.status = BookingStatus.requested,
  });

  VehicleBooking copyWith({BookingStatus? status}) => VehicleBooking(
    id: id,
    vehicleId: vehicleId,
    vehicleLabel: vehicleLabel,
    category: category,
    requesterId: requesterId,
    requesterName: requesterName,
    providerId: providerId,
    pickup: pickup,
    drop: drop,
    distanceKm: distanceKm,
    farePaise: farePaise,
    scheduledAt: scheduledAt,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'vehicle_label': vehicleLabel,
    'category': category.name,
    'requester_id': requesterId,
    'requester_name': requesterName,
    'provider_id': providerId,
    'pickup': pickup,
    'drop': drop,
    'distance_km': distanceKm,
    'fare_paise': farePaise,
    'scheduled_at': scheduledAt.toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory VehicleBooking.fromMap(Map<dynamic, dynamic> m) => VehicleBooking(
    id: m['id'] as String? ?? '',
    vehicleId: m['vehicle_id'] as String? ?? '',
    vehicleLabel: m['vehicle_label'] as String? ?? '',
    category: VehicleCategoryX.fromId(m['category'] as String? ?? 'goods'),
    requesterId: m['requester_id'] as String? ?? '',
    requesterName: m['requester_name'] as String? ?? '',
    providerId: m['provider_id'] as String? ?? '',
    pickup: m['pickup'] as String? ?? '',
    drop: m['drop'] as String? ?? '',
    distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
    farePaise: (m['fare_paise'] as num?)?.toInt() ?? 0,
    scheduledAt:
        DateTime.tryParse(m['scheduled_at'] as String? ?? '') ?? DateTime.now(),
    status: BookingStatusX.fromId(m['status'] as String? ?? 'requested'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// investments table/collection — foreign investor → landowner projects. INR only.
class Investment {
  final String id;
  final String investorId;
  final String investorName;
  final String projectId;
  final String projectTitle;
  final String landownerId;
  final String landownerName;
  final int amountPaise;
  final PaymentStatus status;
  final DateTime createdAt;

  const Investment({
    required this.id,
    required this.investorId,
    required this.investorName,
    required this.projectId,
    required this.projectTitle,
    required this.landownerId,
    required this.landownerName,
    required this.amountPaise,
    required this.createdAt,
    this.status = PaymentStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'investor_id': investorId,
    'investor_name': investorName,
    'project_id': projectId,
    'project_title': projectTitle,
    'landowner_id': landownerId,
    'landowner_name': landownerName,
    'amount_paise': amountPaise,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory Investment.fromMap(Map<dynamic, dynamic> m) => Investment(
    id: m['id'] as String? ?? '',
    investorId: m['investor_id'] as String? ?? '',
    investorName: m['investor_name'] as String? ?? '',
    projectId: m['project_id'] as String? ?? '',
    projectTitle: m['project_title'] as String? ?? '',
    landownerId: m['landowner_id'] as String? ?? '',
    landownerName: m['landowner_name'] as String? ?? '',
    amountPaise: (m['amount_paise'] as num?)?.toInt() ?? 0,
    status: PaymentStatusX.fromId(m['status'] as String? ?? 'pending'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
