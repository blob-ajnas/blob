import 'package:blob/core/utils/money.dart';
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
}
