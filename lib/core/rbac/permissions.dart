import '../../data/models/enums.dart';
import '../../data/models/role_subtype.dart';

/// Capability-based RBAC. Screens and widgets ask
/// `Rbac.can(role, Permission.x)` instead of hardcoding role checks.
///
/// Two layers:
///  * [Rbac._matrix]       — what every account of a role can do.
///  * [Rbac._subtypeGrants] — extra capabilities unlocked by the account's
///    chosen specialisation, so sub-types change real behaviour instead of
///    being a cosmetic label.
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
  bookTaxi,
  rentVehicle,
  manageFleet,
  manageRentals,
  provideTaxi,
  listProperty,
  browseProperty,
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
      Permission.bookTaxi,
      Permission.rentVehicle,
      Permission.browseProperty,
      Permission.listProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.buyer: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.postJobs,
      Permission.assignLaborers,
      Permission.bookGoodsVehicle,
      Permission.bookTaxi,
      Permission.rentVehicle,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.broker: {
      Permission.browseMarket,
      Permission.facilitateDeals,
      Permission.earnCommission,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
    UserRole.laborer: {
      Permission.applyToJobs,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.transport: {
      Permission.manageFleet,
      Permission.browseMarket,
      Permission.viewPaymentTracker,
    },
    UserRole.foreignInvestor: {
      Permission.browseMarket,
      Permission.investInProjects,
      Permission.browseProperty,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.globalExporter: {
      Permission.browseMarket,
      Permission.buyProducts,
      Permission.expediteShipping,
      Permission.bookGoodsVehicle,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.taxiService: {
      Permission.provideTaxi,
      Permission.manageFleet,
      Permission.viewPaymentTracker,
    },
    UserRole.vehicleRental: {
      Permission.manageRentals,
      Permission.manageFleet,
      Permission.viewPaymentTracker,
    },
    UserRole.propertyOwner: {
      Permission.listProperty,
      Permission.browseProperty,
      Permission.bookTaxi,
      Permission.viewPaymentTracker,
    },
    UserRole.admin: {
      Permission.approveAccounts,
      Permission.browseMarket,
      Permission.browseProperty,
      Permission.viewPaymentTracker,
    },
  };

  /// Capabilities added on top of the role baseline by a specialisation.
  static const Map<RoleSubtype, Set<Permission>> _subtypeGrants = {
    // Only wholesale buyers move stock onward to exporters; retail buyers
    // sell into local shops and mandis instead.
    RoleSubtype.wholesaleHarvestBuyer: {Permission.resellToExporters},
    // A labour agent supplies crews, so they need the hiring side too.
    RoleSubtype.labourAgentContract: {
      Permission.postJobs,
      Permission.assignLaborers,
    },
    // Agri-tech and infrastructure investors evaluate physical assets.
    RoleSubtype.farmInfrastructureEquity: {Permission.browseProperty},
    RoleSubtype.agriTechExpansion: {Permission.browseProperty},
    // Inter-state wholesale exporters book domestic freight directly.
    RoleSubtype.interStateWholesaleExport: {Permission.bookGoodsVehicle},
    // Land lessors are usually cultivators too.
    RoleSubtype.agricultureLandLease: {
      Permission.browseMarket,
      Permission.listCrops,
    },
  };

  static Set<Permission> of(UserRole role, {RoleSubtype? subtype}) {
    final base = _matrix[role] ?? const <Permission>{};
    final extra = subtype == null
        ? const <Permission>{}
        : (_subtypeGrants[subtype] ?? const <Permission>{});
    if (extra.isEmpty) return base;
    return {...base, ...extra};
  }

  static bool can(
    UserRole role,
    Permission permission, {
    RoleSubtype? subtype,
  }) {
    if (_matrix[role]?.contains(permission) ?? false) return true;
    if (subtype == null) return false;
    return _subtypeGrants[subtype]?.contains(permission) ?? false;
  }
}
