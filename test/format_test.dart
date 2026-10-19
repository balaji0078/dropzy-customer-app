import 'package:dropzy_mobile/core_api/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatInr (§1.8)', () {
    test('contract examples', () {
      expect(formatInr(4720), '₹47.20');
      expect(formatInr(181900), '₹1,819.00');
    });
    test('Indian grouping and small values', () {
      expect(formatInr(0), '₹0.00');
      expect(formatInr(5), '₹0.05');
      expect(formatInr(99999), '₹999.99');
      expect(formatInr(100000), '₹1,000.00');
      expect(formatInr(10000000), '₹1,00,000.00');
      expect(formatInr(1234567890), '₹1,23,45,678.90');
    });
    test('moneyText prefers server display', () {
      expect(moneyText(5782, '₹57.82'), '₹57.82');
      expect(moneyText(5782, null), '₹57.82');
      expect(moneyText(null), '₹0.00');
    });
  });

  group('weights (PRICING.md §4.5)', () {
    test('formatKg', () {
      expect(formatKg(500), '0.50 kg');
      expect(formatKg(1250), '1.25 kg');
      expect(formatKg(1251), '1.251 kg');
      expect(formatKg(800), '0.80 kg');
      expect(formatKg(5), '0.005 kg');
      expect(formatKg(50000), '50.00 kg');
    });
    test('signed difference', () {
      expect(formatSignedKg(300), '+0.30 kg');
      expect(formatSignedKg(-200), '−0.20 kg');
      expect(formatSignedKg(0), '0.00 kg');
    });
    test('grams and tax rate', () {
      expect(formatGrams(50), '50 g');
      expect(formatBpsPercent(1800), '18%');
      expect(formatBpsPercent(1850), '18.5%');
      expect(formatBpsPercent(1825), '18.25%');
    });
    test('parseWeightGrams uses the server regexes', () {
      expect(parseWeightGrams('0.8', 'kg'), 800);
      expect(parseWeightGrams('1.25', 'kg'), 1250);
      expect(parseWeightGrams('0.005', 'kg'), 5);
      expect(parseWeightGrams('2', 'kg'), 2000);
      expect(parseWeightGrams('500', 'g'), 500);
      for (final bad in [' 1', '1 ', '1,0', '1.2345', '-1', '+1', '1e3', '', '.5', '1.']) {
        expect(parseWeightGrams(bad, 'kg'), isNull, reason: bad);
      }
      expect(parseWeightGrams('0.5', 'g'), isNull);
      expect(parseWeightGrams('1234567', 'g'), isNull);
      expect(parseWeightGrams('1', 'lb'), isNull);
    });
    test('validateDeclaredWeight bounds', () {
      expect(validateDeclaredWeight('0.5', 'kg', minGrams: 1, maxGrams: 50000), isNull);
      expect(validateDeclaredWeight('51', 'kg', minGrams: 1, maxGrams: 50000), contains('between'));
      expect(validateDeclaredWeight('0', 'g', minGrams: 1, maxGrams: 50000), isNotNull);
      expect(validateDeclaredWeight('abc', 'kg'), isNotNull);
    });
  });

  group('time (IST)', () {
    final t = DateTime.utc(2026, 10, 19, 10, 5); // 15:35 IST
    test('dd MMM, hh:mm a', () => expect(formatIst(t), '19 Oct, 03:35 PM'));
    test('§6.2 deadline order', () => expect(formatIstDeadline(t), '03:35 PM, 19 Oct'));
    test('date param crosses midnight in IST', () {
      expect(istDateParam(DateTime.utc(2026, 10, 19, 19, 0)), '2026-10-20');
      expect(istDateParam(DateTime.utc(2026, 10, 19, 18, 0)), '2026-10-19');
    });
    test('bookable dates: today .. +6 IST', () {
      final d = bookableIstDates(DateTime.utc(2026, 10, 19, 19, 0));
      expect(d.length, 7);
      expect(istDateParam(d.first), '2026-10-20');
      expect(istDateParam(d.last), '2026-10-26');
    });
    test('countdown', () {
      expect(formatCountdown(const Duration(hours: 1, minutes: 25)), '1 h 25 min');
      expect(formatCountdown(const Duration(hours: 2)), '2 h 0 min');
      expect(formatCountdown(const Duration(minutes: 59, seconds: 59)), '59 min');
      expect(formatCountdown(const Duration(seconds: 59)), 'less than a minute');
      expect(formatCountdown(Duration.zero), 'less than a minute');
    });
  });

  group('inputs', () {
    test('phone', () {
      expect(isValidPhone('9000000001'), isTrue);
      expect(isValidPhone('5000000001'), isFalse);
      expect(isValidPhone('900000000'), isFalse);
      expect(localPhone('+919000000001'), '9000000001');
      expect(maskPhone('+919876543210'), '+91******3210');
    });
    test('declared value rupees → paise', () {
      expect(rupeesToPaise('1500'), 150000);
      expect(rupeesToPaise('1500.5'), 150050);
      expect(rupeesToPaise('12.345'), isNull);
      expect(rupeesToPaise('abc'), isNull);
    });
  });
}
