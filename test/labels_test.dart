import 'package:dropzy_mobile/core_api/deep_links.dart';
import 'package:dropzy_mobile/core_api/gates.dart';
import 'package:dropzy_mobile/core_api/labels.dart';
import 'package:dropzy_mobile/core_api/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShipmentView _view(Map<String, dynamic> extra) => ShipmentView.fromJson({
      'id': 's1',
      'state': 'SURCHARGE_PAYMENT_PENDING',
      'stateLabel': 'Extra weight charge due',
      'version': 3,
      'serverTime': '2026-10-19T08:00:00Z',
      'allowedActions': <String>[],
      'blockedActions': <dynamic>[],
      'route': {
        'origin': {'id': 'o', 'name': 'Chennai CMBT'},
        'destination': {'id': 'd', 'name': 'Bengaluru Majestic'},
        'loadGateEnabled': true,
      },
      ...extra,
    });

void main() {
  group('§2.4 state labels', () {
    test('all 20 states have icon + tone', () {
      expect(shipmentStateSpecs.length, 20);
      expect(stateSpec('PAYMENT_PENDING').icon, Icons.schedule_rounded);
      expect(stateSpec('PAYMENT_FAILED').icon, Icons.error_outline_rounded);
      expect(stateSpec('EXPIRED').icon, Icons.block_rounded);
      expect(stateSpec('WEIGHT_CHECK_REQUIRED').icon, Icons.scale_rounded);
      expect(stateSpec('ACCEPTED_AT_ORIGIN').icon, Icons.handshake_rounded);
      expect(stateSpec('LOADED').icon, Icons.directions_bus_rounded);
      expect(stateSpec('ARRIVED_AT_DESTINATION').icon, Icons.place_rounded);
      expect(stateSpec('WAREHOUSE_HOLD_UNPAID').icon, Icons.lock_rounded);
      expect(stateSpec('READY_FOR_PICKUP').icon, Icons.storefront_rounded);
      expect(stateSpec('PICKED_UP').icon, Icons.done_all_rounded);
      expect(stateSpec('RETURNED').icon, Icons.undo_rounded);
    });
    test('server stateLabel is shown verbatim; template is the fallback', () {
      expect(stateLabelText('BOOKED', 'Booked — hand over at Chennai CMBT'), 'Booked — hand over at Chennai CMBT');
      expect(stateLabelText('BOOKED', null, originStop: 'Chennai CMBT'), 'Booked — hand over at Chennai CMBT');
      expect(stateLabelText('ARRIVED_AT_DESTINATION', '', destinationStop: 'Majestic'), 'Arrived at Majestic');
      expect(stateLabelText('SOMETHING_NEW', null), 'Status updated');
    });
    test('terminal / pre-payment sets', () {
      for (final s in ['EXPIRED', 'DELIVERED', 'PICKED_UP', 'CANCELLED', 'RETURNED']) {
        expect(isTerminalState(s), isTrue, reason: s);
      }
      expect(isTerminalState('IN_TRANSIT'), isFalse);
      expect(prePaymentStates.contains('BOOKED'), isFalse);
    });
  });

  group('§2.5 surcharge customerLabel', () {
    test('chip text', () {
      expect(surchargeLabelSpec('NONE'), isNull);
      expect(surchargeLabelSpec(null), isNull);
      expect(surchargeLabelSpec('PAYMENT_DUE')!.text, 'Payment due');
      expect(surchargeLabelSpec('VERIFYING')!.text, 'Verifying payment');
      expect(surchargeLabelSpec('PAYMENT_FAILED')!.text, 'Payment failed — try again');
      expect(surchargeLabelSpec('PAYMENT_FAILED')!.icon, Icons.error_outline_rounded);
      expect(surchargeLabelSpec('PAID')!.text, 'Paid');
      expect(surchargeLabelSpec('WAIVED')!.text, 'Waived');
      expect(surchargeLabelSpec('DISPUTED')!.text, 'Under dispute');
      expect(surchargeLabelSpec('OVERDUE_WAREHOUSE')!.text, 'Overdue — warehouse pickup');
    });
  });

  group('gates (§1.7)', () {
    test('enabled only from allowedActions, blocker message shown', () {
      final s = _view({
        'allowedActions': ['OPEN_DISPUTE'],
        'blockedActions': [
          {'action': 'PAY_SURCHARGE', 'code': 'PAYMENT_PENDING', 'message': 'Verifying your payment… Do not pay again.'}
        ],
      });
      expect(gateFor(s, 'OPEN_DISPUTE').enabled, isTrue);
      final pay = gateFor(s, 'PAY_SURCHARGE');
      expect(pay.enabled, isFalse);
      expect(pay.blockerMessage, 'Verifying your payment… Do not pay again.');
      expect(gateFor(s, 'CANCEL_BOOKING').enabled, isFalse);
    });
    test('surcharge pay disabled for VERIFYING / PAID / WAIVED even if allowed', () {
      final s = _view({'allowedActions': ['PAY_SURCHARGE']});
      for (final l in ['VERIFYING', 'PAID', 'WAIVED']) {
        expect(surchargePayGate(s, SurchargeStatus(customerLabel: l)).enabled, isFalse, reason: l);
      }
      expect(surchargePayGate(s, SurchargeStatus(customerLabel: 'PAYMENT_FAILED')).enabled, isTrue);
      expect(surchargePayGate(s, SurchargeStatus(customerLabel: 'PAYMENT_DUE')).enabled, isTrue);
    });
  });

  group('§6.2 / §6.3 copy', () {
    test('before cutoff with load gate at origin', () {
      final s = _view({'warehouse': {'info': {'name': 'Bengaluru Hub'}}});
      final sc = SurchargeStatus(
          customerLabel: 'PAYMENT_DUE', paymentDeadline: DateTime.utc(2026, 10, 19, 10, 5));
      final lines = surchargeDeadlineCopy(s, sc, DateTime.utc(2026, 10, 19, 8, 40));
      expect(lines.first.headline, 'Pay by 03:35 PM, 19 Oct (1 h 25 min left)');
      expect(lines.first.body,
          'If unpaid by then, your parcel will not be handed over at Bengaluru Majestic. It will be held at Bengaluru Hub for pickup after payment.');
      expect(lines.last.headline, 'Your parcel will be loaded only after this payment is verified.');
    });
    test('after cutoff', () {
      final s = _view({'cutoffPassed': true});
      final lines = surchargeDeadlineCopy(s, SurchargeStatus(customerLabel: 'OVERDUE_WAREHOUSE', deadlinePassed: true), DateTime.now());
      expect(lines.first.headline, 'Payment deadline passed');
    });
    test('warehouse hold unpaid card', () {
      final s = _view({
        'state': 'WAREHOUSE_HOLD_UNPAID',
        'cutoffAt': '2026-10-19T10:05:00Z',
        'warehouse': {
          'info': {'name': 'Bengaluru Hub', 'address': '12 MG Road', 'openingHours': '9 AM–7 PM'}
        },
        'surcharge': {'driverLabel': 'WAREHOUSE_HOLD', 'driverLabelText': 'Warehouse hold', 'customerLabel': 'OVERDUE_WAREHOUSE', 'amountDuePaise': 4720},
      });
      final c = warehouseCardCopy(s)!;
      expect(c.title, 'Held at Bengaluru Hub — payment due');
      expect(c.body, contains('extra weight charge of ₹47.20 was not paid by 19 Oct, 03:35 PM'));
      expect(c.payAmount, '₹47.20');
    });
    test('home banner', () {
      final s = ShipmentSummary.fromJson({
        'id': 'x', 'state': 'SURCHARGE_PAYMENT_PENDING', 'stateLabel': 'Extra weight charge due',
        'dcn': 'DCN-MAA-BLR-2026-000123', 'amountDuePaise': 4720, 'surchargeDue': true,
        'cutoffAt': '2026-10-19T10:05:00Z',
      });
      expect(surchargeBannerText(s), 'Extra charge due for DCN-MAA-BLR-2026-000123 — pay ₹47.20 by 03:35 PM, 19 Oct');
    });
  });

  group('deep links', () {
    test('parse', () {
      expect(parseDeepLink(Uri.parse('dropzy://shipments/abc')), const ShipmentLink('abc'));
      expect(parseDeepLink(Uri.parse('dropzy://shipments/abc/pay')), const SurchargePayLink('abc'));
      expect(parseDeepLink(Uri.parse('dropzy://payments/return?intentId=i1')), const PaymentReturnLink('i1'));
      expect(parseDeepLink(Uri.parse('dropzy://payments/return')), const PaymentReturnLink(null));
      expect(parseDeepLink(Uri.parse('dropzy:///shipments/abc')), const ShipmentLink('abc'));
      expect(parseDeepLink(Uri.parse('https://shipments/abc')), isNull);
      expect(parseDeepLink(Uri.parse('dropzy://unknown')), isNull);
    });
    test('notification data', () {
      expect(deepLinkFromNotification({'screen': 'surchargePay', 'shipmentId': 's'}), const SurchargePayLink('s'));
      expect(deepLinkFromNotification({'screen': 'shipment', 'shipmentId': 's'}), const ShipmentLink('s'));
      expect(deepLinkFromNotification({}, fallbackShipmentId: 's'), const ShipmentLink('s'));
      expect(deepLinkFromNotification({}), isNull);
    });
  });
}
