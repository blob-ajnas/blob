import 'package:blob/core/i18n/strings.dart';
import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/utils/money.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/role_subtype.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INR money formatting', () {
    test('formats paise into Indian rupee notation', () {
      expect(Money.format(250000), '\u20B92,500');
      expect(Money.format(5000), '\u20B950');
    });

    test('job posting fee is fifty rupees', () {
      expect(Money.jobPostingFeePaise, 5000);
      expect(Money.format(Money.jobPostingFeePaise), '\u20B950');
    });

    test('first two posts are free', () {
      expect(Money.freeJobPostLimit, 2);
    });

    test('broker commission is 2.5 percent', () {
      expect(Money.brokerCommissionOn(1000000), 25000);
    });

    test('rupee to paise conversion avoids float drift', () {
      expect(Money.rupeesToPaise(2300.55), 230055);
    });
  });

  group('Role sub-types', () {
    test('every sub-type maps back to exactly one role', () {
      for (final subtype in RoleSubtype.values) {
        expect(
          RoleSubtypeX.forRole(subtype.role),
          contains(subtype),
          reason: '${subtype.name} is not listed under ${subtype.role.name}',
        );
      }
    });

    test('every sub-type has a label, description and icon', () {
      for (final subtype in RoleSubtype.values) {
        expect(subtype.label, isNotEmpty);
        expect(subtype.description, isNotEmpty);
        expect(subtype.icon, isNotNull);
      }
    });

    test('roles requiring a choice expose at least two options', () {
      for (final role in UserRole.values) {
        final options = RoleSubtypeX.forRole(role);
        if (RoleSubtypeX.hasSubtypes(role)) {
          expect(options.length, greaterThanOrEqualTo(2));
          expect(RoleSubtypeX.defaultFor(role), options.first);
        } else {
          expect(options, isEmpty);
        }
      }
    });

    test('landowner and admin deliberately have no sub-types', () {
      expect(RoleSubtypeX.hasSubtypes(UserRole.landowner), isFalse);
      expect(RoleSubtypeX.hasSubtypes(UserRole.admin), isFalse);
    });

    test('id round-trips and unknown ids fall back to null', () {
      for (final subtype in RoleSubtype.values) {
        expect(RoleSubtypeX.tryFromId(subtype.id), subtype);
      }
      expect(RoleSubtypeX.tryFromId('not_a_subtype'), isNull);
      expect(RoleSubtypeX.tryFromId(null), isNull);
    });

    test('vehicle categories are wired to the right verticals', () {
      expect(
        RoleSubtype.heavyTransportTruck.vehicleCategory,
        VehicleCategory.goods,
      );
      expect(
        RoleSubtype.travellerBus.vehicleCategory,
        VehicleCategory.passenger,
      );
      expect(
        RoleSubtype.bikeScooterRental.vehicleCategory,
        VehicleCategory.rental,
      );
      expect(RoleSubtype.retailMarketBuyer.vehicleCategory, isNull);
    });

    test('only rentals are billed per day', () {
      expect(VehicleCategory.rental.isDailyRate, isTrue);
      expect(VehicleCategory.goods.isDailyRate, isFalse);
      expect(VehicleCategory.passenger.isDailyRate, isFalse);
    });

    test('land is measured in acres, buildings in square feet', () {
      expect(RoleSubtype.agricultureLandLease.areaUnit, 'acre');
      expect(RoleSubtype.commercialBuilding.areaUnit, 'sq ft');
      expect(RoleSubtype.residentialQuarters.areaUnit, 'sq ft');
    });

    test('property kinds are exactly the property owner sub-types', () {
      expect(
        RoleSubtypeX.propertyKinds,
        RoleSubtypeX.forRole(UserRole.propertyOwner),
      );
      expect(RoleSubtypeX.propertyKinds.length, 3);
    });
  });

  group('Capability RBAC', () {
    test('every role has a permission set', () {
      for (final role in UserRole.values) {
        expect(Rbac.of(role), isNotEmpty, reason: 'role ${role.name}');
      }
    });

    test('sub-types change behaviour, not just labels', () {
      // Only wholesale buyers may resell into the export channel.
      expect(
        Rbac.can(
          UserRole.buyer,
          Permission.resellToExporters,
          subtype: RoleSubtype.wholesaleHarvestBuyer,
        ),
        isTrue,
      );
      expect(
        Rbac.can(
          UserRole.buyer,
          Permission.resellToExporters,
          subtype: RoleSubtype.retailMarketBuyer,
        ),
        isFalse,
      );

      // Labour-agent brokers can hire crews; crop-commission brokers cannot.
      expect(
        Rbac.can(
          UserRole.broker,
          Permission.postJobs,
          subtype: RoleSubtype.labourAgentContract,
        ),
        isTrue,
      );
      expect(
        Rbac.can(
          UserRole.broker,
          Permission.postJobs,
          subtype: RoleSubtype.cropCommissionDeal,
        ),
        isFalse,
      );
    });

    test('a sub-type only ever adds capability, never removes it', () {
      for (final subtype in RoleSubtype.values) {
        final base = Rbac.of(subtype.role);
        final withSubtype = Rbac.of(subtype.role, subtype: subtype);
        expect(withSubtype, containsAll(base), reason: subtype.name);
      }
    });

    test('service providers own their vertical', () {
      expect(Rbac.can(UserRole.taxiService, Permission.provideTaxi), isTrue);
      expect(
        Rbac.can(UserRole.vehicleRental, Permission.manageRentals),
        isTrue,
      );
      expect(
        Rbac.can(UserRole.propertyOwner, Permission.listProperty),
        isTrue,
      );
      // Goods transport must not be able to run a taxi business.
      expect(Rbac.can(UserRole.transport, Permission.provideTaxi), isFalse);
    });

    test('landowners can list land without switching roles', () {
      expect(Rbac.can(UserRole.landowner, Permission.listProperty), isTrue);
      expect(Rbac.can(UserRole.landowner, Permission.browseProperty), isTrue);
    });

    test('only admins can approve accounts', () {
      for (final role in UserRole.values) {
        expect(
          Rbac.can(role, Permission.approveAccounts),
          role == UserRole.admin,
          reason: 'role ${role.name}',
        );
      }
    });

    test('commercial permits gate the right roles', () {
      expect(UserRole.taxiService.requiresApproval, isTrue);
      expect(UserRole.vehicleRental.requiresApproval, isTrue);
      expect(UserRole.broker.requiresApproval, isTrue);
      expect(UserRole.globalExporter.requiresApproval, isTrue);
      expect(UserRole.landowner.requiresApproval, isFalse);
      expect(UserRole.propertyOwner.requiresApproval, isFalse);
    });
  });

  group('Localisation', () {
    test('all seven languages are available', () {
      expect(AppLanguage.values.length, 7);
      expect(
        AppLanguage.values.map((l) => l.code).toList(),
        ['en', 'kn', 'mr', 'ml', 'ta', 'te', 'hi'],
      );
    });

    test('every language has a native display name', () {
      for (final lang in AppLanguage.values) {
        expect(lang.nativeName, isNotEmpty, reason: lang.code);
      }
    });

    test('no translation key falls back to a raw key name', () {
      const keys = [
        'app_tagline',
        'welcome_title',
        'get_started',
        'choose_language',
        'continue_label',
        'login_title',
        'phone_number',
        'send_code',
        'otp_title',
        'verify',
        'choose_role',
        'role_hint',
        'choose_specialisation',
        'specialisation_hint',
        'your_name',
        'district',
        'create_account',
        'home',
        'market',
        'jobs',
        'payments',
        'profile',
        'property',
        'rides',
        'rentals',
        'fleet',
        'approvals',
        'cleared',
        'pending',
        'logout',
      ];
      for (final lang in AppLanguage.values) {
        for (final key in keys) {
          final value = S.t(lang, key);
          expect(value, isNotEmpty, reason: '${lang.code}/$key');
          expect(value, isNot(key), reason: 'missing ${lang.code}/$key');
        }
      }
    });
  });
}
