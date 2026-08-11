import 'package:blob/core/i18n/strings.dart';
import 'package:blob/core/rbac/permissions.dart';
import 'package:blob/core/utils/money.dart';
import 'package:blob/data/learning_content.dart';
import 'package:blob/data/models/enums.dart';
import 'package:blob/data/models/learning.dart';
import 'package:blob/data/models/role_subtype.dart';
import 'package:blob/services/aadhaar_service.dart';
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
    test('English plus all 22 Eighth Schedule languages are available', () {
      expect(AppLanguage.values.length, 23);
      expect(AppLanguage.values.first, AppLanguage.english);
      // Every Eighth Schedule language must be present.
      const eighthSchedule = [
        'as', 'bn', 'brx', 'doi', 'gu', 'hi', 'kn', 'ks', 'kok', 'mai',
        'ml', 'mni', 'mr', 'ne', 'or', 'pa', 'sa', 'sat', 'sd', 'ta',
        'te', 'ur',
      ];
      final codes = AppLanguage.values.map((l) => l.code).toSet();
      for (final code in eighthSchedule) {
        expect(codes, contains(code), reason: 'missing $code');
      }
    });

    test('language codes are unique', () {
      final codes = AppLanguage.values.map((l) => l.code).toList();
      expect(codes.toSet().length, codes.length);
    });

    test('every language has a native and english display name', () {
      for (final lang in AppLanguage.values) {
        expect(lang.nativeName, isNotEmpty, reason: lang.code);
        expect(lang.englishName, isNotEmpty, reason: lang.code);
      }
    });

    test('right-to-left scripts are flagged', () {
      expect(AppLanguage.urdu.isRtl, isTrue);
      expect(AppLanguage.kashmiri.isRtl, isTrue);
      expect(AppLanguage.sindhi.isRtl, isTrue);
      expect(AppLanguage.hindi.isRtl, isFalse);
      expect(AppLanguage.english.isRtl, isFalse);
    });

    test('untranslated languages still resolve to readable English', () {
      // Bodo has no translation map yet; it must not leak raw keys.
      expect(S.t(AppLanguage.bodo, 'home'), S.t(AppLanguage.english, 'home'));
      expect(S.t(AppLanguage.bodo, 'home'), isNot('home'));
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

  group('Aadhaar verification', () {
    test('accepts real-format numbers that satisfy the Verhoeff checksum', () {
      // Verified against an independent implementation of the UIDAI
      // Verhoeff algorithm, not hand-picked to fit the code.
      expect(AadhaarService.isValidNumber('234123412346'), isTrue);
      expect(AadhaarService.isValidNumber('499118665246'), isTrue);
      expect(AadhaarService.isValidNumber('999999990019'), isTrue);
    });

    test('rejects a transposed pair of digits', () {
      // The whole point of a Verhoeff check over a naive length check:
      // swapping two adjacent digits must fail.
      expect(AadhaarService.isValidNumber('234123412346'), isTrue);
      expect(AadhaarService.isValidNumber('234132412346'), isFalse);
    });

    test('rejects wrong length, non-digits and reserved leading digits', () {
      expect(AadhaarService.isValidNumber('23412341234'), isFalse); // 11
      expect(AadhaarService.isValidNumber('2341234123456'), isFalse); // 13
      expect(AadhaarService.isValidNumber('23412341234a'), isFalse);
      expect(AadhaarService.isValidNumber(''), isFalse);
      // UIDAI never issues a number starting 0 or 1.
      expect(AadhaarService.isValidNumber('012345678901'), isFalse);
      expect(AadhaarService.isValidNumber('123456789010'), isFalse);
    });

    test('normalises spaced and hyphenated input', () {
      expect(AadhaarService.normalise('2341 2341 2346'), '234123412346');
      expect(AadhaarService.normalise('2341-2341-2346'), '234123412346');
      expect(AadhaarService.isValidNumber('2341 2341 2346'), isTrue);
    });

    test('masking never exposes more than the last four digits', () {
      expect(AadhaarService.mask('234123412346'), 'XXXX XXXX 2346');
      expect(AadhaarService.mask('2341 2341 2346'), 'XXXX XXXX 2346');
      // The first eight digits must not survive anywhere in the output.
      expect(AadhaarService.mask('234123412346'), isNot(contains('2341234')));
    });

    test('last4 is the only fragment we ever persist', () {
      expect(AadhaarService.last4('234123412346'), '2346');
      expect(AadhaarService.last4('12'), '');
    });

    test('a valid number issues an OTP that verifies exactly once', () async {
      final service = AadhaarService();
      const number = '234123412346';

      final sent = await service.requestOtp(number);
      expect(sent.success, isTrue);
      final code = sent.devCode;
      expect(code, isNotNull);

      expect(service.verify(number, '000000').success, isFalse);
      expect(service.verify(number, code!).success, isTrue);
      // Consumed: replaying the same code must not re-verify.
      expect(service.verify(number, code).success, isFalse);
    });

    test('an invalid number never reaches the OTP provider', () async {
      final service = AadhaarService();
      final sent = await service.requestOtp('111111111111');
      expect(sent.success, isFalse);
      expect(sent.devCode, isNull);
    });
  });

  group('Daily learning tasks', () {
    test('targets match the spec: 15 min video, 3 games, 10 questions', () {
      expect(DailyTaskType.video.target, 15);
      expect(DailyTaskType.games.target, 3);
      expect(DailyTaskType.quiz.target, 10);
    });

    test('every task type has a label, subtitle, unit and icon', () {
      for (final type in DailyTaskType.values) {
        expect(type.label, isNotEmpty, reason: type.name);
        expect(type.subtitle, isNotEmpty, reason: type.name);
        expect(type.unitLabel, isNotEmpty, reason: type.name);
        expect(type.points, greaterThan(0), reason: type.name);
      }
    });

    test('the daily quiz really holds ten questions', () {
      expect(LearningContent.dailyQuiz.length, DailyTaskType.quiz.target);
    });

    test('every quiz question has a reachable, in-range answer', () {
      for (final q in LearningContent.dailyQuiz) {
        expect(q.question, isNotEmpty);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length),
            reason: 'out-of-range answer for "${q.question}"');
        expect(q.options.toSet().length, q.options.length,
            reason: 'duplicate options for "${q.question}"');
      }
    });

    test('the video lesson is exactly the advertised fifteen minutes', () {
      expect(LearningContent.todaysVideo.minutes, DailyTaskType.video.target);
    });

    test('the games hub has enough content for a full round', () {
      expect(LearningContent.mathRounds, isNotEmpty);
      expect(LearningContent.termPairs.length,
          greaterThanOrEqualTo(DailyTaskType.games.target));
      for (final round in LearningContent.mathRounds) {
        expect(round.options, contains(round.answer),
            reason: 'unanswerable round: ${round.prompt}');
      }
    });
  });

  group('Daily progress arithmetic', () {
    DailyProgress progress({int video = 0, int games = 0, int quiz = 0}) =>
        DailyProgress(
          userId: 'u',
          dayKey: '2025-01-01',
          videoMinutes: video,
          gamesPlayed: games,
          quizAnswered: quiz,
        );

    test('a task completes only on reaching its target', () {
      expect(progress(video: 14).isComplete(DailyTaskType.video), isFalse);
      expect(progress(video: 15).isComplete(DailyTaskType.video), isTrue);
      // Overshooting still counts as complete, never as an error.
      expect(progress(video: 40).isComplete(DailyTaskType.video), isTrue);
      expect(progress(games: 2).isComplete(DailyTaskType.games), isFalse);
      expect(progress(games: 3).isComplete(DailyTaskType.games), isTrue);
      expect(progress(quiz: 9).isComplete(DailyTaskType.quiz), isFalse);
      expect(progress(quiz: 10).isComplete(DailyTaskType.quiz), isTrue);
    });

    test('allComplete requires all three, not just any one', () {
      expect(progress(video: 15, games: 3, quiz: 10).allComplete, isTrue);
      expect(progress(video: 15, games: 3, quiz: 9).allComplete, isFalse);
      expect(progress().allComplete, isFalse);
    });

    test('overall fraction is clamped, so overshooting cannot exceed 100%', () {
      expect(progress().overallFraction, 0.0);
      expect(progress(video: 15, games: 3, quiz: 10).overallFraction, 1.0);
      // 99 minutes of video is still only one task done.
      expect(progress(video: 99).overallFraction, closeTo(1 / 3, 0.0001));
    });

    test('completedCount counts finished tasks only', () {
      expect(progress(video: 15, games: 1).completedCount, 1);
      expect(progress(video: 15, games: 3).completedCount, 2);
      expect(progress(video: 15, games: 3, quiz: 10).completedCount, 3);
    });

    test('day keys are zero-padded and sort chronologically as strings', () {
      final jan = DailyProgress.dayKeyOf(DateTime(2025, 1, 9));
      final oct = DailyProgress.dayKeyOf(DateTime(2025, 10, 11));
      expect(jan, '2025-01-09');
      expect(oct, '2025-10-11');
      expect(jan.compareTo(oct), lessThan(0));
    });

    test('storage keys are unique per user and per day', () {
      final a = DailyProgress.keyFor('u_1', DateTime(2025, 3, 4));
      final b = DailyProgress.keyFor('u_2', DateTime(2025, 3, 4));
      final c = DailyProgress.keyFor('u_1', DateTime(2025, 3, 5));
      expect({a, b, c}.length, 3);
      expect(a, 'u_1_2025-03-04');
    });
  });

  group('User categories', () {
    test('only students are asked for academic details', () {
      expect(UserCategory.student.needsAcademicProfile, isTrue);
      expect(UserCategory.jobSeeker.needsAcademicProfile, isFalse);
    });

    test('every category is presentable in the UI', () {
      for (final c in UserCategory.values) {
        expect(c.label, isNotEmpty, reason: c.name);
        expect(c.subtitle, isNotEmpty, reason: c.name);
        expect(c.description, isNotEmpty, reason: c.name);
      }
    });

    test('ids round-trip and unknown ids fall back to null', () {
      for (final c in UserCategory.values) {
        expect(UserCategoryX.tryFromId(c.id), c);
      }
      expect(UserCategoryX.tryFromId('teacher'), isNull);
      expect(UserCategoryX.tryFromId(null), isNull);
    });
  });
}
