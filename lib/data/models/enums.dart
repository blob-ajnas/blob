/// BLOB domain enumerations.
library;

enum UserRole {
  buyer,
  landowner,
  broker,
  laborer,
  transport,
  foreignInvestor,
  globalExporter,
  admin,
}

extension UserRoleX on UserRole {
  String get id => name;

  String get label => switch (this) {
    UserRole.buyer => 'Buyer',
    UserRole.landowner => 'Landowner',
    UserRole.broker => 'Broker',
    UserRole.laborer => 'Laborer',
    UserRole.transport => 'Transport',
    UserRole.foreignInvestor => 'Foreign Investor',
    UserRole.globalExporter => 'Global Exporter',
    UserRole.admin => 'Administrator',
  };

  /// Roles that must be approved by an admin before gaining full access.
  bool get requiresApproval =>
      this == UserRole.broker || this == UserRole.globalExporter;

  static UserRole fromId(String value) =>
      UserRole.values.firstWhere((e) => e.name == value,
          orElse: () => UserRole.buyer);
}

enum LaborerType { singleWorker, groupWork }

extension LaborerTypeX on LaborerType {
  String get label => switch (this) {
    LaborerType.singleWorker => 'Single Worker',
    LaborerType.groupWork => 'Group Work',
  };

  String get description => switch (this) {
    LaborerType.singleWorker =>
      'Individual services — shops, hotels, domestic help',
    LaborerType.groupWork => 'Team labor — harvesting, factory shifts',
  };

  static LaborerType fromId(String value) => LaborerType.values
      .firstWhere((e) => e.name == value, orElse: () => LaborerType.singleWorker);
}

enum VerificationStatus { pending, approved, rejected }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
    VerificationStatus.pending => 'Pending Approval',
    VerificationStatus.approved => 'Verified',
    VerificationStatus.rejected => 'Rejected',
  };

  static VerificationStatus fromId(String value) =>
      VerificationStatus.values.firstWhere((e) => e.name == value,
          orElse: () => VerificationStatus.approved);
}

enum JobType { single, group }

enum JobStatus { open, assigned, inProgress, completed, cancelled }

extension JobStatusX on JobStatus {
  String get label => switch (this) {
    JobStatus.open => 'Open',
    JobStatus.assigned => 'Assigned',
    JobStatus.inProgress => 'In Progress',
    JobStatus.completed => 'Completed',
    JobStatus.cancelled => 'Cancelled',
  };

  static JobStatus fromId(String value) =>
      JobStatus.values.firstWhere((e) => e.name == value,
          orElse: () => JobStatus.open);
}

enum ApplicationStatus { applied, assigned, accepted, completed, rejected }

extension ApplicationStatusX on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.assigned => 'Assigned',
    ApplicationStatus.accepted => 'Accepted',
    ApplicationStatus.completed => 'Completed',
    ApplicationStatus.rejected => 'Not Selected',
  };

  static ApplicationStatus fromId(String value) =>
      ApplicationStatus.values.firstWhere((e) => e.name == value,
          orElse: () => ApplicationStatus.applied);
}

enum ListingStatus { active, reserved, sold, withdrawn }

extension ListingStatusX on ListingStatus {
  String get label => switch (this) {
    ListingStatus.active => 'Active',
    ListingStatus.reserved => 'Reserved',
    ListingStatus.sold => 'Sold',
    ListingStatus.withdrawn => 'Withdrawn',
  };

  static ListingStatus fromId(String value) =>
      ListingStatus.values.firstWhere((e) => e.name == value,
          orElse: () => ListingStatus.active);
}

/// Who the listing is offered to — drives the supply chain.
enum ListingChannel { toBuyers, toExporters }

extension ListingChannelX on ListingChannel {
  String get label => switch (this) {
    ListingChannel.toBuyers => 'Open to Buyers',
    ListingChannel.toExporters => 'Open to Exporters',
  };

  static ListingChannel fromId(String value) =>
      ListingChannel.values.firstWhere((e) => e.name == value,
          orElse: () => ListingChannel.toBuyers);
}

enum PaymentStatus { pending, cleared, failed }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.cleared => 'Cleared',
    PaymentStatus.failed => 'Failed',
  };

  static PaymentStatus fromId(String value) =>
      PaymentStatus.values.firstWhere((e) => e.name == value,
          orElse: () => PaymentStatus.pending);
}

/// Ledger entry classification.
enum LedgerType {
  laborWage,
  brokerCommission,
  productPurchase,
  transportFare,
  investment,
  jobPostingFee,
}

extension LedgerTypeX on LedgerType {
  String get label => switch (this) {
    LedgerType.laborWage => 'Labor Wage',
    LedgerType.brokerCommission => 'Broker Commission',
    LedgerType.productPurchase => 'Product Purchase',
    LedgerType.transportFare => 'Transport Fare',
    LedgerType.investment => 'Investment',
    LedgerType.jobPostingFee => 'Job Posting Fee',
  };

  static LedgerType fromId(String value) =>
      LedgerType.values.firstWhere((e) => e.name == value,
          orElse: () => LedgerType.laborWage);
}

enum VehicleCategory { goods, passenger }

extension VehicleCategoryX on VehicleCategory {
  String get label => switch (this) {
    VehicleCategory.goods => 'Goods Vehicle',
    VehicleCategory.passenger => 'Passenger Vehicle',
  };

  String get description => switch (this) {
    VehicleCategory.goods => 'Commercial transport for agricultural goods',
    VehicleCategory.passenger => 'Transit for people and work crews',
  };

  static VehicleCategory fromId(String value) =>
      VehicleCategory.values.firstWhere((e) => e.name == value,
          orElse: () => VehicleCategory.goods);
}

enum BookingStatus { requested, confirmed, enRoute, delivered, cancelled }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.requested => 'Requested',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.enRoute => 'En Route',
    BookingStatus.delivered => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };

  static BookingStatus fromId(String value) =>
      BookingStatus.values.firstWhere((e) => e.name == value,
          orElse: () => BookingStatus.requested);
}
