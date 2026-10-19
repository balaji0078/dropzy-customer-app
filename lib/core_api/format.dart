import 'package:intl/intl.dart';

/// Display formatting shared by every core screen (CLIENT_CONTRACTS.md §1.8,
/// PRICING.md §3 and §4.5). Pure functions — unit tested.

/// `4720 → ₹47.20`, `181900 → ₹1,819.00`, `10000000 → ₹1,00,000.00`.
/// Integer arithmetic only (no doubles). The API never sends negative amounts;
/// if one ever arrives it is shown with a minus sign rather than hidden.
String formatInr(int paise) {
  final negative = paise < 0;
  final p = paise.abs();
  final rupees = p ~/ 100;
  final ps = (p % 100).toString().padLeft(2, '0');
  return '${negative ? '−' : ''}₹${_indianGrouping(rupees)}.$ps';
}

String _indianGrouping(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Prefer the server-rendered `*Display` string, else format the paise.
String moneyText(int? paise, [String? display]) {
  if (display != null && display.trim().isNotEmpty) return display.trim();
  return formatInr(paise ?? 0);
}

/// PRICING.md §4.5 FormatKg: `500 → 0.50 kg`, `1250 → 1.25 kg`, `1251 → 1.251 kg`.
String formatKg(int grams) {
  final g = grams.abs();
  final whole = g ~/ 1000;
  final rem = g % 1000;
  final sign = grams < 0 ? '−' : '';
  if (g % 10 == 0) return '$sign$whole.${(rem ~/ 10).toString().padLeft(2, '0')} kg';
  return '$sign$whole.${rem.toString().padLeft(3, '0')} kg';
}

/// Signed difference: `+0.30 kg`, `−0.20 kg` (U+2212), `0.00 kg`.
String formatSignedKg(int grams) {
  if (grams > 0) return '+${formatKg(grams)}';
  if (grams < 0) return '−${formatKg(-grams)}';
  return formatKg(0);
}

/// Small gram quantities such as the tolerance: `50 g`.
String formatGrams(int grams) => '$grams g';

/// `1800 → 18%`, `1850 → 18.5%`.
String formatBpsPercent(int bps) {
  final whole = bps ~/ 100;
  final frac = bps % 100;
  if (frac == 0) return '$whole%';
  var f = frac.toString().padLeft(2, '0');
  if (f.endsWith('0')) f = f.substring(0, 1);
  return '$whole.$f%';
}

// ─── Time (IST, UTC+05:30, no DST) ───

DateTime toIst(DateTime t) => t.toUtc().add(const Duration(hours: 5, minutes: 30));

/// §1.8: `dd MMM, hh:mm a` → "19 Oct, 03:35 PM".
String formatIst(DateTime t) => DateFormat('dd MMM, hh:mm a').format(toIst(t));

/// §6.2 deadline order: "03:35 PM, 19 Oct".
String formatIstDeadline(DateTime t) => DateFormat('hh:mm a, dd MMM').format(toIst(t));

/// "03:35 PM".
String formatIstClock(DateTime t) => DateFormat('hh:mm a').format(toIst(t));

/// "Mon, 19 Oct".
String formatIstDay(DateTime t) => DateFormat('EEE, dd MMM').format(toIst(t));

/// IST calendar date for API `date` params: "2026-10-19".
String istDateParam(DateTime t) => DateFormat('yyyy-MM-dd').format(toIst(t));

/// IST service dates bookable from [now]: today .. +6 days (C5).
List<DateTime> bookableIstDates(DateTime now) {
  final ist = toIst(now);
  final day0 = DateTime.utc(ist.year, ist.month, ist.day);
  // Represent each IST midnight as the UTC instant 05:30 earlier.
  return List.generate(7, (i) => day0.add(Duration(days: i)).subtract(const Duration(hours: 5, minutes: 30)));
}

/// §1.8 countdown: "1 h 25 min", "25 min", "less than a minute".
String formatCountdown(Duration d) {
  if (d.inSeconds < 60) return 'less than a minute';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h >= 1) return '$h h $m min';
  return '$m min';
}

// ─── Input validation ───

final RegExp phonePattern = RegExp(r'^[6-9][0-9]{9}$');
final RegExp _gramsPattern = RegExp(r'^[0-9]{1,6}$');
final RegExp _kgPattern = RegExp(r'^([0-9]{1,3})(?:\.([0-9]{1,3}))?$');

bool isValidPhone(String v) => phonePattern.hasMatch(v);

/// Strips `+91` from an E.164 Indian number for the 10-digit field.
String localPhone(String? e164) {
  final p = (e164 ?? '').replaceAll(RegExp(r'\s'), '');
  if (p.startsWith('+91') && p.length == 13) return p.substring(3);
  return p;
}

/// "+91******3210" (display only).
String maskPhone(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 4) return phone ?? '';
  return '+91******${digits.substring(digits.length - 4)}';
}

/// PRICING.md §3 string conversion (same rules as the server):
/// g: `^[0-9]{1,6}$`; kg: `^[0-9]{1,3}(\.[0-9]{1,3})?$` → grams; else null.
int? parseWeightGrams(String value, String unit) {
  if (unit == 'g') {
    if (!_gramsPattern.hasMatch(value)) return null;
    return int.parse(value);
  }
  if (unit == 'kg') {
    final m = _kgPattern.firstMatch(value);
    if (m == null) return null;
    final whole = int.parse(m.group(1)!);
    final frac = (m.group(2) ?? '').padRight(3, '0');
    return whole * 1000 + int.parse(frac);
  }
  return null;
}

/// Client-side declared-weight check (server re-validates). Returns an error
/// message or null when valid.
String? validateDeclaredWeight(String value, String unit, {int? minGrams, int? maxGrams}) {
  if (value.isEmpty) return 'Enter the declared weight.';
  final g = parseWeightGrams(value, unit);
  if (g == null) {
    return unit == 'g'
        ? 'Enter whole grams, e.g. 500.'
        : 'Enter kilograms with up to 3 decimals, e.g. 0.5.';
  }
  final min = minGrams ?? 1;
  if (g < min || (maxGrams != null && g > maxGrams)) {
    return maxGrams == null
        ? 'Declared weight must be at least ${formatKg(min)}.'
        : 'Declared weight must be between ${formatKg(min)} and ${formatKg(maxGrams)}.';
  }
  return null;
}

/// Declared value typed in rupees ("1500" or "1500.50") → paise; null if invalid.
int? rupeesToPaise(String v) {
  final m = RegExp(r'^([0-9]{1,9})(?:\.([0-9]{1,2}))?$').firstMatch(v.trim());
  if (m == null) return null;
  return int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
}
