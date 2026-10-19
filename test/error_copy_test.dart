import 'package:dropzy_mobile/core/error_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OTP copy with variables', () {
    expect(ErrorCopy.forCode('OTP_THROTTLED', {'retryAfterSeconds': 30}), 'Too many attempts. Try again in 30 s.');
    expect(ErrorCopy.forCode('OTP_INVALID', {'attemptsRemaining': 3}), 'Incorrect code. 3 attempts left.');
    expect(ErrorCopy.forCode('OTP_EXPIRED'), 'Code expired. Tap Resend.');
    expect(
      ErrorCopy.forCode('OTP_THROTTLED', {'retryAfterSeconds': 3600, 'reason': 'LOCKED'}, DateTime.utc(2026, 10, 19, 9, 5)),
      'Too many wrong codes. For your security this number is locked until 19 Oct, 03:35 PM.',
    );
  });

  test('booking / payment / dispute copy', () {
    expect(ErrorCopy.forCode('CAPACITY_UNAVAILABLE'), 'This bus is now full. Please choose another trip.');
    expect(ErrorCopy.forCode('QUOTE_EXPIRED'), 'Price expired — refreshing.');
    expect(ErrorCopy.forCode('DISPUTE_NOT_ALLOWED'), 'This charge cannot be disputed now.');
    expect(ErrorCopy.forCode('BOOKING_NOT_CANCELLABLE'),
        'This booking can no longer be cancelled because the parcel has been handed over.');
    expect(ErrorCopy.forCode('PAYMENT_PROVIDER_UNAVAILABLE'), startsWith('Payments are temporarily unavailable.'));
    expect(ErrorCopy.forCode('SESSION_REVOKED'), 'Your session has ended. Please log in again.');
  });

  test('fallbacks: server message, then generic', () {
    expect(ErrorCopy.resolve(code: 'NOT_FOUND', serverMessage: 'Shipment not found.'), 'Shipment not found.');
    expect(ErrorCopy.resolve(code: 'OTP_INVALID', serverMessage: 'Wrong code'), 'Wrong code');
    expect(ErrorCopy.resolve(code: 'WHATEVER'), ErrorCopy.generic);
    expect(ErrorCopy.resolve(code: 'OTP_EXPIRED', serverMessage: 'x'), 'Code expired. Tap Resend.');
  });
}
