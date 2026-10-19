import '../core_api/format.dart';

/// Customer-facing copy keyed by core `error.code`
/// (CLIENT_CONTRACTS.md §1.2, §2.1, §6). Fallback is the server's
/// `error.message`, which the API guarantees is safe to show.
class ErrorCopy {
  ErrorCopy._();

  static const sessionEnded = 'Your session has ended. Please log in again.';
  static const network = 'Cannot reach the server. Check your connection.';
  static const generic = 'Something went wrong. Please try again.';
  static const providerUnavailable =
      'Payments are temporarily unavailable. Your parcel stays on hold until '
      'payment is confirmed. Try again in a few minutes or contact support.';
  static const verifying = 'Verifying your payment… Do not pay again.';

  /// §6 copy for [code], or null when the contract defines none (or a
  /// required variable is missing from [details]).
  static String? forCode(String? code, [Map<String, dynamic> details = const {}, DateTime? now]) {
    switch (code) {
      case 'OTP_THROTTLED':
        final s = _int(details['retryAfterSeconds']);
        if (s == null) return null;
        if (details['reason'] == 'LOCKED') {
          final until = (now ?? DateTime.now()).add(Duration(seconds: s));
          return 'Too many wrong codes. For your security this number is locked until ${formatIst(until)}.';
        }
        return 'Too many attempts. Try again in $s s.';
      case 'OTP_INVALID':
        final n = _int(details['attemptsRemaining']);
        return n == null ? null : 'Incorrect code. $n attempts left.';
      case 'OTP_EXPIRED':
        return 'Code expired. Tap Resend.';
      case 'CAPACITY_UNAVAILABLE':
        return 'This bus is now full. Please choose another trip.';
      case 'QUOTE_EXPIRED':
        return 'Price expired — refreshing.';
      case 'DISPUTE_NOT_ALLOWED':
        return 'This charge cannot be disputed now.';
      case 'BOOKING_NOT_CANCELLABLE':
        return 'This booking can no longer be cancelled because the parcel has been handed over.';
      case 'PAYMENT_PROVIDER_UNAVAILABLE':
        return providerUnavailable;
      case 'PAYMENT_PENDING':
        return verifying;
      case 'SESSION_REVOKED':
      case 'UNAUTHENTICATED':
        return sessionEnded;
      case 'NETWORK':
        return network;
    }
    return null;
  }

  /// Final message to show: §6 copy → server message → generic.
  static String resolve({
    String? code,
    Map<String, dynamic> details = const {},
    String? serverMessage,
    DateTime? now,
  }) {
    final copy = forCode(code, details, now);
    if (copy != null) return copy;
    if (serverMessage != null && serverMessage.trim().isNotEmpty) return serverMessage.trim();
    return generic;
  }

  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}'));
}
