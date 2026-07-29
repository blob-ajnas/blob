import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/money.dart';
import '../data/local_db.dart';
import '../data/models/app_user.dart';
import '../data/models/enums.dart';
import '../data/models/job.dart';
import '../data/models/ledger.dart';
import '../data/models/listing.dart';
import '../data/models/vehicle.dart';
import '../services/payment_gateway.dart';

class JobPostOutcome {
  final bool success;
  final String message;
  final int feeChargedPaise;

  const JobPostOutcome({
    required this.success,
    required this.message,
    this.feeChargedPaise = 0,
  });
}

/// Central marketplace store: listings, jobs, applications, ledger,
/// vehicles, bookings and investments.
class MarketplaceController extends ChangeNotifier {
  MarketplaceController({PaymentGateway? gateway})
      : _gateway = gateway ?? StubPaymentGateway();

  final PaymentGateway _gateway;
  final _db = LocalDb.instance;
  final _uuid = const Uuid();

  // ---------------- Reads ----------------

  List<AppUser> get users =>
      _db.all(LocalDb.users).map(AppUser.fromMap).toList();

  List<Listing> get listings {
    final items = _db.all(LocalDb.listings).map(Listing.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Job> get jobs {
    final items = _db.all(LocalDb.jobs).map(Job.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<JobApplication> get applications => _db
      .all(LocalDb.applications)
      .map(JobApplication.fromMap)
      .toList();

  List<LedgerEntry> get ledger {
    final items = _db.all(LocalDb.ledger).map(LedgerEntry.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Vehicle> get vehicles =>
      _db.all(LocalDb.vehicles).map(Vehicle.fromMap).toList();

  List<VehicleBooking> get bookings {
    final items =
        _db.all(LocalDb.bookings).map(VehicleBooking.fromMap).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Investment> get investments =>
      _db.all(LocalDb.investments).map(Investment.fromMap).toList();

  // ---------------- Scoped queries (simple filters, sorted in memory) ----

  List<Listing> listingsFor(ListingChannel channel) => listings
      .where((l) => l.channel == channel && l.status == ListingStatus.active)
      .toList();

  List<Listing> listingsByOwner(String ownerId) =>
      listings.where((l) => l.ownerId == ownerId).toList();

  List<Job> jobsByPoster(String posterId) =>
      jobs.where((j) => j.posterId == posterId).toList();

  List<Job> openJobs() =>
      jobs.where((j) => j.status == JobStatus.open).toList();

  List<JobApplication> applicationsForJob(String jobId) =>
      applications.where((a) => a.jobId == jobId).toList();

  List<JobApplication> applicationsByLaborer(String laborerId) {
    final items =
        applications.where((a) => a.laborerId == laborerId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<Vehicle> vehiclesByOwner(String ownerId) =>
      vehicles.where((v) => v.ownerId == ownerId).toList();

  List<Vehicle> availableVehicles(VehicleCategory category) => vehicles
      .where((v) => v.category == category && v.available)
      .toList();

  List<VehicleBooking> bookingsForUser(String userId) => bookings
      .where((b) => b.requesterId == userId || b.providerId == userId)
      .toList();

  List<LedgerEntry> ledgerFor(String userId) => ledger
      .where((e) => e.payerId == userId || e.payeeId == userId)
      .toList();

  int pendingIncomingPaise(String userId) => ledger
      .where((e) => e.payeeId == userId && e.status == PaymentStatus.pending)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int clearedIncomingPaise(String userId) => ledger
      .where((e) => e.payeeId == userId && e.status == PaymentStatus.cleared)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int pendingOutgoingPaise(String userId) => ledger
      .where((e) => e.payerId == userId && e.status == PaymentStatus.pending)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int clearedOutgoingPaise(String userId) => ledger
      .where((e) => e.payerId == userId && e.status == PaymentStatus.cleared)
      .fold(0, (sum, e) => sum + e.amountPaise);

  int commissionEarnedPaise(String brokerId) => ledger
      .where((e) =>
          e.payeeId == brokerId && e.type == LedgerType.brokerCommission)
      .fold(0, (sum, e) => sum + e.amountPaise);

  List<AppUser> pendingApprovals() => users
      .where((u) => u.verificationStatus == VerificationStatus.pending)
      .toList();

  List<AppUser> usersByRole(UserRole role) =>
      users.where((u) => u.role == role && u.isApproved).toList();

  // ---------------- Listings ----------------

  Future<Listing> createListing({
    required AppUser owner,
    required String cropName,
    required String description,
    required double quantityQuintal,
    required int pricePerQuintalPaise,
    required ListingChannel channel,
  }) async {
    final listing = Listing(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      ownerRole: owner.role,
      cropName: cropName,
      description: description,
      quantityQuintal: quantityQuintal,
      pricePerQuintalPaise: pricePerQuintalPaise,
      district: owner.district,
      channel: channel,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.listings, listing.id, listing.toMap());
    notifyListeners();
    return listing;
  }

  Future<void> updateListingStatus(Listing listing, ListingStatus status) async {
    final updated = listing.copyWith(status: status);
    await _db.put(LocalDb.listings, updated.id, updated.toMap());
    notifyListeners();
  }

  /// Purchase a listing. Creates a pending ledger entry for the seller and,
  /// when a broker facilitated the deal, an automatic commission entry.
  Future<void> purchaseListing({
    required Listing listing,
    required AppUser buyer,
    AppUser? broker,
  }) async {
    await _addLedger(
      payerId: buyer.id,
      payerName: buyer.name,
      payeeId: listing.ownerId,
      payeeName: listing.ownerName,
      amountPaise: listing.totalPaise,
      type: LedgerType.productPurchase,
      reference: listing.id,
      note: '${listing.cropName} · ${listing.quantityQuintal} quintal',
    );

    if (broker != null) {
      final commission = Money.brokerCommissionOn(listing.totalPaise);
      await _addLedger(
        payerId: buyer.id,
        payerName: buyer.name,
        payeeId: broker.id,
        payeeName: broker.name,
        amountPaise: commission,
        type: LedgerType.brokerCommission,
        reference: listing.id,
        note: 'Commission 2.5% · ${listing.cropName}',
      );
    }

    await updateListingStatus(listing, ListingStatus.sold);
  }

  // ---------------- Jobs & monetization ----------------

  /// First 2 posts per user are free; ₹50 from the 3rd onward.
  int postingFeeFor(AppUser user) =>
      user.freeJobPostsUsed < Money.freeJobPostLimit
          ? 0
          : Money.jobPostingFeePaise;

  int freePostsRemaining(AppUser user) =>
      (Money.freeJobPostLimit - user.freeJobPostsUsed)
          .clamp(0, Money.freeJobPostLimit);

  Future<JobPostOutcome> postJob({
    required AppUser poster,
    required String title,
    required String description,
    required JobType jobType,
    required int workersNeeded,
    required int wagePerWorkerPaise,
    required DateTime workDate,
    required Future<void> Function(AppUser updated) onPosterUpdated,
  }) async {
    final fee = postingFeeFor(poster);

    if (fee > 0) {
      final result = await _gateway.charge(
        amountPaise: fee,
        description: 'Job posting fee',
        payerId: poster.id,
      );
      if (!result.success) {
        return JobPostOutcome(success: false, message: result.message);
      }
      await _addLedger(
        payerId: poster.id,
        payerName: poster.name,
        payeeId: 'platform',
        payeeName: 'BLOB Platform',
        amountPaise: fee,
        type: LedgerType.jobPostingFee,
        reference: 'job_fee',
        note: 'Job posting fee',
        status: PaymentStatus.cleared,
      );
    }

    final job = Job(
      id: _uuid.v4(),
      posterId: poster.id,
      posterName: poster.name,
      posterRole: poster.role,
      title: title,
      description: description,
      jobType: jobType,
      workersNeeded: workersNeeded,
      wagePerWorkerPaise: wagePerWorkerPaise,
      district: poster.district,
      workDate: workDate,
      postingFeePaise: fee,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.jobs, job.id, job.toMap());

    final updatedPoster =
        poster.copyWith(freeJobPostsUsed: poster.freeJobPostsUsed + 1);
    await _db.put(LocalDb.users, updatedPoster.id, updatedPoster.toMap());
    await onPosterUpdated(updatedPoster);

    notifyListeners();
    return JobPostOutcome(
      success: true,
      message: fee > 0
          ? 'Job posted · ${Money.format(fee)} fee charged'
          : 'Job posted free',
      feeChargedPaise: fee,
    );
  }

  Future<void> applyToJob({
    required Job job,
    required AppUser laborer,
    int groupSize = 1,
  }) async {
    final already = applications.any(
      (a) => a.jobId == job.id && a.laborerId == laborer.id,
    );
    if (already) return;

    final app = JobApplication(
      id: _uuid.v4(),
      jobId: job.id,
      laborerId: laborer.id,
      laborerName: laborer.name,
      laborerType: laborer.laborerType ?? LaborerType.singleWorker,
      groupSize: groupSize,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.applications, app.id, app.toMap());
    notifyListeners();
  }

  Future<void> assignApplication(JobApplication app, Job job) async {
    final updated = app.copyWith(status: ApplicationStatus.assigned);
    await _db.put(LocalDb.applications, updated.id, updated.toMap());
    await _db.put(
      LocalDb.jobs,
      job.id,
      job.copyWith(status: JobStatus.assigned).toMap(),
    );
    notifyListeners();
  }

  Future<void> acceptAssignment(JobApplication app) async {
    final updated = app.copyWith(status: ApplicationStatus.accepted);
    await _db.put(LocalDb.applications, updated.id, updated.toMap());
    final job = jobs.where((j) => j.id == app.jobId).firstOrNull;
    if (job != null) {
      await _db.put(
        LocalDb.jobs,
        job.id,
        job.copyWith(status: JobStatus.inProgress).toMap(),
      );
    }
    notifyListeners();
  }

  /// Completing a job creates the wage payable to the laborer.
  Future<void> completeJob({
    required Job job,
    required JobApplication app,
  }) async {
    await _db.put(
      LocalDb.applications,
      app.id,
      app.copyWith(status: ApplicationStatus.completed).toMap(),
    );
    await _db.put(
      LocalDb.jobs,
      job.id,
      job.copyWith(status: JobStatus.completed).toMap(),
    );

    final wage = job.wagePerWorkerPaise * app.groupSize;
    await _addLedger(
      payerId: job.posterId,
      payerName: job.posterName,
      payeeId: app.laborerId,
      payeeName: app.laborerName,
      amountPaise: wage,
      type: LedgerType.laborWage,
      reference: job.id,
      note: job.title,
    );
    notifyListeners();
  }

  // ---------------- Vehicles & bookings ----------------

  Future<void> addVehicle({
    required AppUser owner,
    required VehicleCategory category,
    required String vehicleType,
    required String registrationNumber,
    required double capacityValue,
    required int ratePerKmPaise,
  }) async {
    final vehicle = Vehicle(
      id: _uuid.v4(),
      ownerId: owner.id,
      ownerName: owner.name,
      category: category,
      vehicleType: vehicleType,
      registrationNumber: registrationNumber,
      capacityValue: capacityValue,
      ratePerKmPaise: ratePerKmPaise,
      district: owner.district,
    );
    await _db.put(LocalDb.vehicles, vehicle.id, vehicle.toMap());
    notifyListeners();
  }

  Future<void> toggleVehicleAvailability(Vehicle v) async {
    final updated = v.copyWith(available: !v.available);
    await _db.put(LocalDb.vehicles, updated.id, updated.toMap());
    notifyListeners();
  }

  Future<VehicleBooking> bookVehicle({
    required Vehicle vehicle,
    required AppUser requester,
    required String pickup,
    required String drop,
    required double distanceKm,
    required DateTime scheduledAt,
  }) async {
    final fare = (vehicle.ratePerKmPaise * distanceKm).round();
    final booking = VehicleBooking(
      id: _uuid.v4(),
      vehicleId: vehicle.id,
      vehicleLabel: '${vehicle.vehicleType} · ${vehicle.registrationNumber}',
      category: vehicle.category,
      requesterId: requester.id,
      requesterName: requester.name,
      providerId: vehicle.ownerId,
      pickup: pickup,
      drop: drop,
      distanceKm: distanceKm,
      farePaise: fare,
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.bookings, booking.id, booking.toMap());

    await _addLedger(
      payerId: requester.id,
      payerName: requester.name,
      payeeId: vehicle.ownerId,
      payeeName: vehicle.ownerName,
      amountPaise: fare,
      type: LedgerType.transportFare,
      reference: booking.id,
      note: '$pickup to $drop · ${distanceKm.toStringAsFixed(0)} km',
    );
    notifyListeners();
    return booking;
  }

  Future<void> updateBookingStatus(
      VehicleBooking booking, BookingStatus status) async {
    await _db.put(
      LocalDb.bookings,
      booking.id,
      booking.copyWith(status: status).toMap(),
    );
    notifyListeners();
  }

  // ---------------- Investments ----------------

  Future<void> createInvestment({
    required AppUser investor,
    required Listing project,
    required int amountPaise,
  }) async {
    final inv = Investment(
      id: _uuid.v4(),
      investorId: investor.id,
      investorName: investor.name,
      projectId: project.id,
      projectTitle: project.cropName,
      landownerId: project.ownerId,
      landownerName: project.ownerName,
      amountPaise: amountPaise,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.investments, inv.id, inv.toMap());
    await _addLedger(
      payerId: investor.id,
      payerName: investor.name,
      payeeId: project.ownerId,
      payeeName: project.ownerName,
      amountPaise: amountPaise,
      type: LedgerType.investment,
      reference: project.id,
      note: 'Investment · ${project.cropName}',
    );
    notifyListeners();
  }

  // ---------------- Ledger ----------------

  Future<void> _addLedger({
    required String payerId,
    required String payerName,
    required String payeeId,
    required String payeeName,
    required int amountPaise,
    required LedgerType type,
    required String reference,
    required String note,
    PaymentStatus status = PaymentStatus.pending,
  }) async {
    final entry = LedgerEntry(
      id: _uuid.v4(),
      payerId: payerId,
      payerName: payerName,
      payeeId: payeeId,
      payeeName: payeeName,
      amountPaise: amountPaise,
      type: type,
      status: status,
      reference: reference,
      note: note,
      createdAt: DateTime.now(),
      clearedAt: status == PaymentStatus.cleared ? DateTime.now() : null,
    );
    await _db.put(LocalDb.ledger, entry.id, entry.toMap());
  }

  /// Clears a pending payout through the gateway.
  Future<bool> clearPayment(LedgerEntry entry) async {
    if (entry.status == PaymentStatus.cleared) return true;
    final result = await _gateway.payout(
      amountPaise: entry.amountPaise,
      payeeId: entry.payeeId,
      description: entry.note,
    );
    if (!result.success) return false;
    final updated = entry.copyWith(
      status: PaymentStatus.cleared,
      clearedAt: DateTime.now(),
    );
    await _db.put(LocalDb.ledger, updated.id, updated.toMap());
    notifyListeners();
    return true;
  }

  Future<void> clearAllPending(String payerId) async {
    final pending = ledger
        .where((e) => e.payerId == payerId && e.status == PaymentStatus.pending)
        .toList();
    for (final e in pending) {
      await clearPayment(e);
    }
  }

  // ---------------- Admin ----------------

  Future<void> setVerification(AppUser user, VerificationStatus status) async {
    final updated = user.copyWith(verificationStatus: status);
    await _db.put(LocalDb.users, updated.id, updated.toMap());
    notifyListeners();
  }
}
