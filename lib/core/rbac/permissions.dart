import '../../data/models/enums.dart';

/// Capability-based RBAC. Screens and widgets ask
/// `Rbac.can(role, Permission.x)` instead of hardcoding role checks.
enum Permission {
  listCrops,
  browseMarket,
  buyProducts,
  resellToExporters,
  postJobs,
  applyToJobs,
  assignLaborers,
  discoverInvestors,
  investInProjects,
  bookGoodsVehicle,
  bookPassengerVehicle,
  manageFleet,
  facilitateDeals,
  earnCommission,
  expediteShipping,
  viewPaymentTracker,
  approveAccounts,
}

class Rbac {
  Rbac._();

  static const Map<UserRole, Set<Permission>> _matrix = {
    UserRole.landowner: {
      Permission.listCrops,
      Permission.browseMarket,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.discoverInvestors,
      Permission.bookGoodsVehicle,
      Permission.bookPassengerVehicle,
      Permission.viewPaymentTracker,
    },
    UserRole.buyer: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.resellToExporters,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.bookGoodsVehicle,
      Permission.bookPassengerVehicle,
      Permission.viewPaymentTracker,
    },
    UserRole.broker: {
      Permission.browseMarket,
      Permission.facilitateDeals,
      Permission.earnCommission,
      Permission.viewPaymentTracker,
    },
    UserRole.laborer: {
      Permission.applyToJobs,
      Permission.viewPaymentTracker,
    },
    UserRole.transport: {
      Permission.manageFleet,
      Permission.viewPaymentTracker,
    },
    UserRole.foreignInvestor: {
      Permission.browseMarket,
      Permission.investInProjects,
      Permission.viewPaymentTracker,
    },
    UserRole.globalExporter: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.expediteShipping,
      Permission.bookGoodsVehicle,
      Permission.viewPaymentTracker,
    },
    UserRole.admin: {
      Permission.approveAccounts,
      Permission.browseMarket,
      Permission.viewPaymentTracker,
    },
  };

  static Set<Permission> of(UserRole role) => _matrix[role] ?? const {};

  static bool can(UserRole role, Permission permission) =>
      _matrix[role]?.contains(permission) ?? false;
}
