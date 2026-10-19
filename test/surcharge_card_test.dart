import 'package:dropzy_mobile/core/theme.dart';
import 'package:dropzy_mobile/core_api/models.dart';
import 'package:dropzy_mobile/screens/v2/payment_flow_screen.dart';
import 'package:dropzy_mobile/widgets/v2/surcharge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> surcharge(String label) => {
      'driverLabel': 'AWAITING_PAYMENT',
      'driverLabelText': 'Awaiting payment',
      'customerLabel': label,
      'amountDuePaise': 4720,
      'paymentDeadline': '2026-10-19T10:05:00Z',
      'deadlinePassed': false,
      'currentQuote': {
        'id': 'q1',
        'version': 1,
        'status': 'OPEN',
        'totalPaise': 4720,
        'currency': 'INR',
        'taxRateBps': 1800,
        'tariffVersion': 1,
        'expiresAt': '2026-10-19T12:00:00Z',
        'breakdown': {
          'declaredWeightGrams': 500,
          'actualWeightGrams': 800,
          'rawDifferenceGrams': 300,
          'toleranceGrams': 50,
          'incrementGrams': 500,
          'billableDifferenceGrams': 500,
          'extraUnits': 1,
          'ratePerIncrementPaise': 4000,
          'lines': [
            {'code': 'SURCHARGE', 'label': 'Additional billable weight: 1 × 500 g @ ₹40.00', 'amountPaise': 4000},
            {'code': 'TAX', 'label': 'GST 18% on ₹40.00', 'amountPaise': 720},
          ],
          'totalPaise': 4720,
          'tariffVersion': 1,
          'display': {
            'declared': '0.50 kg',
            'actual': '0.80 kg',
            'rawDifference': '+0.30 kg',
            'billableDifference': '0.50 kg',
            'total': '₹47.20',
          },
        },
      },
    };

ShipmentView shipment({required String label, List<String> allowed = const ['PAY_SURCHARGE', 'OPEN_DISPUTE'], List<Map<String, dynamic>> blocked = const []}) =>
    ShipmentView.fromJson({
      'id': 's1',
      'dcn': 'DCN-MAA-BLR-2026-000123',
      'state': 'SURCHARGE_PAYMENT_PENDING',
      'stateLabel': 'Extra weight charge due',
      'version': 4,
      'serverTime': '2026-10-19T08:40:00Z',
      'route': {
        'destination': {'id': 'd', 'name': 'Bengaluru Majestic'},
        'loadGateEnabled': false,
      },
      'warehouse': {'info': {'name': 'Bengaluru Hub'}},
      'surcharge': surcharge(label),
      'allowedActions': allowed,
      'blockedActions': blocked,
    });

Future<void> pump(WidgetTester tester, ShipmentView s, {VoidCallback? onPay}) => tester.pumpWidget(MaterialApp(
      theme: buildDropzyTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SurchargeCard(
            shipment: s,
            now: DateTime.utc(2026, 10, 19, 8, 40),
            onPay: onPay ?? () {},
            onDispute: () {},
          ),
        ),
      ),
    ));

ElevatedButton payButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.ancestor(of: find.text('Pay ₹47.20'), matching: find.byType(ElevatedButton)));

void main() {
  testWidgets('renders the §6.1 breakdown and §6.2 deadline from server data', (tester) async {
    var taps = 0;
    await pump(tester, shipment(label: 'PAYMENT_DUE'), onPay: () => taps++);
    for (final t in [
      'Extra weight charge',
      'Declared weight', '0.50 kg',
      'Measured weight', '0.80 kg',
      'Difference', '+0.30 kg',
      'Allowed variance', '50 g',
      'Billable extra weight', '0.50 kg (1 × 500 g)',
      'Extra weight (1 × ₹40.00)', '₹40.00',
      'GST 18%', '₹7.20',
      'Total due', '₹47.20',
      'Tariff version 1 · Quote v1',
      'Payment due',
      'Pay by 03:35 PM, 19 Oct (1 h 25 min left)',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.textContaining('Why am I charged?'), findsOneWidget);
    expect(find.text('Dispute this charge'), findsOneWidget);
    expect(payButton(tester).onPressed, isNotNull);
    await tester.tap(find.text('Pay ₹47.20'));
    expect(taps, 1);
  });

  testWidgets('VERIFYING: Pay disabled with "Do not pay again" copy', (tester) async {
    await pump(tester, shipment(label: 'VERIFYING'));
    expect(find.text('Verifying payment'), findsOneWidget);
    expect(payButton(tester).onPressed, isNull);
    expect(find.text('Verifying your payment… Do not pay again.'), findsWidgets);
  });

  testWidgets('blocked PAY_SURCHARGE: disabled and blocker message shown', (tester) async {
    await pump(
      tester,
      shipment(label: 'PAYMENT_DUE', allowed: const ['OPEN_DISPUTE'], blocked: const [
        {'action': 'PAY_SURCHARGE', 'code': 'INVOICE_NOT_PAYABLE', 'message': 'This charge is being updated. Pull to refresh.'}
      ]),
    );
    expect(payButton(tester).onPressed, isNull);
    expect(find.text('This charge is being updated. Pull to refresh.'), findsOneWidget);
  });

  testWidgets('PAID: no pay button, Paid chip', (tester) async {
    await pump(tester, shipment(label: 'PAID'));
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('Pay ₹47.20'), findsNothing);
  });

  test('C10 polling schedule: 3 s for 2 min, then 10 s', () {
    expect(paymentPollInterval(Duration.zero), const Duration(seconds: 3));
    expect(paymentPollInterval(const Duration(seconds: 119)), const Duration(seconds: 3));
    expect(paymentPollInterval(const Duration(minutes: 2)), const Duration(seconds: 10));
  });
}
