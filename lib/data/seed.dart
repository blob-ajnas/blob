import 'local_db.dart';
import 'models/app_user.dart';
import 'models/enums.dart';
import 'models/job.dart';
import 'models/listing.dart';
import 'models/vehicle.dart';

/// Seeds demo marketplace data on first launch so every role dashboard
/// has realistic content. Karnataka districts, INR pricing.
class Seed {
  Seed._();

  static const _kSeeded = 'seed_v1';

  static Future<void> ensure() async {
    final db = LocalDb.instance;
    if (db.setting<bool>(_kSeeded, false)) return;

    final now = DateTime.now();

    final people = <AppUser>[
      AppUser(
        id: 'u_landowner_1',
        phone: '+919845010001',
        countryCode: '+91',
        name: 'Ramesh Gowda',
        role: UserRole.landowner,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      AppUser(
        id: 'u_landowner_2',
        phone: '+919845010002',
        countryCode: '+91',
        name: 'Lakshmamma B',
        role: UserRole.landowner,
        district: 'Hassan',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      AppUser(
        id: 'u_buyer_1',
        phone: '+919845020001',
        countryCode: '+91',
        name: 'Suresh Traders',
        role: UserRole.buyer,
        district: 'Bengaluru Rural',
        createdAt: now.subtract(const Duration(days: 75)),
      ),
      AppUser(
        id: 'u_broker_1',
        phone: '+919845030001',
        countryCode: '+91',
        name: 'Kiran Shetty',
        role: UserRole.broker,
        district: 'Mysuru',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 50)),
      ),
      AppUser(
        id: 'u_broker_2',
        phone: '+919845030002',
        countryCode: '+91',
        name: 'Anitha Rao',
        role: UserRole.broker,
        district: 'Tumakuru',
        verificationStatus: VerificationStatus.pending,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      AppUser(
        id: 'u_laborer_1',
        phone: '+919845040001',
        countryCode: '+91',
        name: 'Manjunath K',
        role: UserRole.laborer,
        laborerType: LaborerType.singleWorker,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      AppUser(
        id: 'u_laborer_2',
        phone: '+919845040002',
        countryCode: '+91',
        name: 'Shivamma Group',
        role: UserRole.laborer,
        laborerType: LaborerType.groupWork,
        district: 'Mandya',
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      AppUser(
        id: 'u_transport_1',
        phone: '+919845050001',
        countryCode: '+91',
        name: 'Vinayaka Logistics',
        role: UserRole.transport,
        district: 'Mysuru',
        createdAt: now.subtract(const Duration(days: 55)),
      ),
      AppUser(
        id: 'u_investor_1',
        phone: '+6591230001',
        countryCode: '+65',
        name: 'Daniel Tan',
        role: UserRole.foreignInvestor,
        companyName: 'GreenAsia Capital',
        country: 'Singapore',
        district: 'Bengaluru Urban',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      AppUser(
        id: 'u_exporter_1',
        phone: '+9715012345',
        countryCode: '+971',
        name: 'Al Noor Foods',
        role: UserRole.globalExporter,
        companyName: 'Al Noor Foods FZE',
        registrationNo: 'FZE-88213',
        country: 'United Arab Emirates',
        district: 'Bengaluru Urban',
        verificationStatus: VerificationStatus.approved,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      AppUser(
        id: 'u_exporter_2',
        phone: '+4477001234',
        countryCode: '+44',
        name: 'Britannia Produce',
        role: UserRole.globalExporter,
        companyName: 'Britannia Produce Ltd',
        registrationNo: 'UK-4471902',
        country: 'United Kingdom',
        district: 'Bengaluru Urban',
        verificationStatus: VerificationStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppUser(
        id: 'u_admin_1',
        phone: '+919000000000',
        countryCode: '+91',
        name: 'BLOB Operations',
        role: UserRole.admin,
        district: 'Bengaluru Urban',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
    ];

    for (final u in people) {
      await db.put(LocalDb.users, u.id, u.toMap());
    }

    final listings = <Listing>[
      Listing(
        id: 'l_1',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        ownerRole: UserRole.landowner,
        cropName: 'Paddy (Sona Masuri)',
        description: 'Freshly harvested, sun-dried, moisture below 14%.',
        quantityQuintal: 120,
        pricePerQuintalPaise: 230000,
        district: 'Mandya',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Listing(
        id: 'l_2',
        ownerId: 'u_landowner_1',
        ownerName: 'Ramesh Gowda',
        ownerRole: UserRole.landowner,
        cropName: 'Sugarcane',
        description: 'Ready for mill delivery, 10 acre yield.',
        quantityQuintal: 800,
        pricePerQuintalPaise: 34000,
        district: 'Mandya',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      Listing(
        id: 'l_3',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        ownerRole: UserRole.landowner,
        cropName: 'Arabica Coffee Parchment',
        description: 'Shade grown, hand picked, Grade A beans.',
        quantityQuintal: 45,
        pricePerQuintalPaise: 1850000,
        district: 'Hassan',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Listing(
        id: 'l_4',
        ownerId: 'u_landowner_2',
        ownerName: 'Lakshmamma B',
        ownerRole: UserRole.landowner,
        cropName: 'Ragi (Finger Millet)',
        description: 'Organic, no chemical fertiliser used.',
        quantityQuintal: 60,
        pricePerQuintalPaise: 380000,
        district: 'Hassan',
        channel: ListingChannel.toBuyers,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Listing(
        id: 'l_5',
        ownerId: 'u_buyer_1',
        ownerName: 'Suresh Traders',
        ownerRole: UserRole.buyer,
        cropName: 'Byadagi Red Chilli',
        description: 'Graded and packed, export ready in 50kg bales.',
        quantityQuintal: 200,
        pricePerQuintalPaise: 1420000,
        district: 'Bengaluru Rural',
        channel: ListingChannel.toExporters,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Listing(
        id: 'l_6',
        ownerId: 'u_buyer_1',
        ownerName: 'Suresh Traders',
        ownerRole: UserRole.buyer,
        cropName: 'Turmeric Fingers',
        description: 'Polished, curcumin 3.2%, fumigation certified.',
        quantityQuintal: 150,
        pricePerQuintalPaise: 960000,
        district: 'Bengaluru Rural',
        channel: ListingChannel.toExporters,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    for (final l in listings) {
      await db.put(LocalDb.listings, l.id, l.toMap());
    }

    final jobs = <Job>[
      Job(
        id: 'j_1',
        posterId: 'u_landowner_1',
        posterName: 'Ramesh Gowda',
        posterRole: UserRole.landowner,
        title: 'Paddy harvesting crew needed',
        description:
            'Need experienced harvesting team for 10 acres. Food provided.',
        jobType: JobType.group,
        workersNeeded: 12,
        wagePerWorkerPaise: 65000,
        district: 'Mandya',
        workDate: now.add(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Job(
        id: 'j_2',
        posterId: 'u_buyer_1',
        posterName: 'Suresh Traders',
        posterRole: UserRole.buyer,
        title: 'Warehouse loading helpers',
        description: 'Loading chilli bales onto containers. 8 hour shift.',
        jobType: JobType.group,
        workersNeeded: 6,
        wagePerWorkerPaise: 80000,
        district: 'Bengaluru Rural',
        workDate: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Job(
        id: 'j_3',
        posterId: 'u_landowner_2',
        posterName: 'Lakshmamma B',
        posterRole: UserRole.landowner,
        title: 'Coffee estate caretaker',
        description: 'Single worker for daily estate upkeep and irrigation.',
        jobType: JobType.single,
        workersNeeded: 1,
        wagePerWorkerPaise: 55000,
        district: 'Hassan',
        workDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (final j in jobs) {
      await db.put(LocalDb.jobs, j.id, j.toMap());
    }

    final vehicles = <Vehicle>[
      Vehicle(
        id: 'v_1',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.goods,
        vehicleType: 'Tata 407 Mini Truck',
        registrationNumber: 'KA 09 C 1234',
        capacityValue: 2.5,
        ratePerKmPaise: 2800,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_2',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.goods,
        vehicleType: 'Ashok Leyland 10-Wheeler',
        registrationNumber: 'KA 09 D 8890',
        capacityValue: 16,
        ratePerKmPaise: 6500,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_3',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.passenger,
        vehicleType: 'Force Traveller',
        registrationNumber: 'KA 09 E 4412',
        capacityValue: 14,
        ratePerKmPaise: 2200,
        district: 'Mysuru',
      ),
      Vehicle(
        id: 'v_4',
        ownerId: 'u_transport_1',
        ownerName: 'Vinayaka Logistics',
        category: VehicleCategory.passenger,
        vehicleType: 'Mahindra Bolero Jeep',
        registrationNumber: 'KA 09 F 7781',
        capacityValue: 7,
        ratePerKmPaise: 1600,
        district: 'Mysuru',
      ),
    ];

    for (final v in vehicles) {
      await db.put(LocalDb.vehicles, v.id, v.toMap());
    }

    await db.setSetting(_kSeeded, true);
  }
}
