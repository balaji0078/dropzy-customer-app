import '../core/error_copy.dart';
import 'format.dart';
import 'labels.dart';
import 'models.dart';

/// Button state derived only from server `allowedActions` / `blockedActions`
/// (CLIENT_CONTRACTS.md §1.7). Clients never re-implement gates.
class ActionGate {
  const ActionGate(this.enabled, [this.blockerMessage]);
  final bool enabled;

  /// Exact UI copy from `blockedActions[].message`, shown under the button.
  final String? blockerMessage;
}

ActionGate gateFor(ShipmentView s, String action) {
  if (s.isAllowed(action)) return const ActionGate(true);
  return ActionGate(false, s.blocker(action)?.message);
}

/// C11: Pay needs `PAY_SURCHARGE` allowed and a customer label that is not
/// VERIFYING / PAID / WAIVED.
ActionGate surchargePayGate(ShipmentView s, SurchargeStatus sc) {
  if (surchargeNoPayLabels.contains(sc.customerLabel)) {
    return ActionGate(false, sc.customerLabel == 'VERIFYING' ? ErrorCopy.verifying : null);
  }
  return gateFor(s, 'PAY_SURCHARGE');
}

/// Amount the customer must pay now, from server fields only.
String surchargeAmountText(SurchargeStatus sc) {
  if (sc.amountDueDisplay != null && sc.amountDueDisplay!.isNotEmpty) return sc.amountDueDisplay!;
  if (sc.amountDuePaise > 0) return formatInr(sc.amountDuePaise);
  final q = sc.currentQuote;
  if (q != null) return moneyText(q.totalPaise, q.breakdown.display['total']);
  return formatInr(0);
}

String warehouseNameOf(ShipmentView s) => s.warehouseInfo?.name ?? 'the destination warehouse';

class CopyLine {
  const CopyLine(this.headline, [this.body]);
  final String headline;
  final String? body;
}

/// CLIENT_CONTRACTS.md §6.2 deadline copy for the surcharge card / sheet.
List<CopyLine> surchargeDeadlineCopy(ShipmentView s, SurchargeStatus sc, DateTime now) {
  final label = sc.customerLabel;
  if (label == 'NONE' || label == 'PAID' || label == 'WAIVED') return const [];
  final lines = <CopyLine>[];
  if (label == 'VERIFYING') lines.add(const CopyLine(ErrorCopy.verifying));
  final wh = warehouseNameOf(s);
  final deadline = sc.paymentDeadline ?? sc.currentQuote?.paymentDeadline ?? s.cutoffAt;
  final passed = sc.deadlinePassed || s.cutoffPassed;
  if (passed) {
    lines.add(CopyLine('Payment deadline passed',
        'Your parcel will be held at $wh. You can still pay now to collect it.'));
  } else if (deadline != null) {
    final left = deadline.difference(now);
    final dest = s.route.destination?.name ?? 'the destination stop';
    lines.add(CopyLine(
      'Pay by ${formatIstDeadline(deadline)} (${formatCountdown(left.isNegative ? Duration.zero : left)} left)',
      'If unpaid by then, your parcel will not be handed over at $dest. '
          'It will be held at $wh for pickup after payment.',
    ));
  }
  if (s.route.loadGateEnabled && atOriginStates.contains(s.state)) {
    lines.add(const CopyLine('Your parcel will be loaded only after this payment is verified.'));
  }
  return lines;
}

const String surchargeWhyCopy =
    'Why am I charged? Your parcel was weighed by the driver at handover. Weights above what you '
    'declared are charged per 500 g (or part), after a 50 g allowance for scale variation.';

class WarehouseCopy {
  const WarehouseCopy({required this.title, required this.body, this.payAmount, this.directions = false});
  final String title;
  final String body;

  /// "Pay {amountDue}" button label amount (WAREHOUSE_HOLD_UNPAID only).
  final String? payAmount;
  final bool directions;
}

/// CLIENT_CONTRACTS.md §6.3 warehouse card. Null → no card.
WarehouseCopy? warehouseCardCopy(ShipmentView s) {
  if (!s.warehousePresent && !s.warehouseRequired) return null;
  final wh = warehouseNameOf(s);
  final address = s.warehouseInfo?.address ?? wh;
  final hours = s.warehouseInfo?.openingHours ?? 'during working hours';
  switch (s.state) {
    case 'WAREHOUSE_HOLD_UNPAID':
      final sc = s.surcharge;
      final amount = sc.amountDuePaise > 0 || sc.amountDueDisplay != null
          ? surchargeAmountText(sc)
          : formatInr(s.warehouseAmountDuePaise ?? 0);
      final deadline = sc.paymentDeadline ?? s.cutoffAt;
      return WarehouseCopy(
        title: 'Held at $wh — payment due',
        body: 'Normal delivery is blocked because the extra weight charge of $amount was not paid by '
            '${deadline == null ? 'the deadline' : formatIst(deadline)}. Pay now in the app. Then collect at: '
            '$address, open $hours. Bring a photo ID — the receiver will get an OTP at the counter.',
        payAmount: amount,
        directions: true,
      );
    case 'WAREHOUSE_HELD_OTHER':
      final msgs = <String>[];
      for (final h in s.activeHolds) {
        final m = (h.customerMessage != null && h.customerMessage!.trim().isNotEmpty)
            ? h.customerMessage!.trim()
            : holdCustomerMessages[h.type];
        if (m != null && !msgs.contains(m)) msgs.add(m);
      }
      final holdMsg = msgs.isEmpty ? 'an operational check is in progress' : msgs.join('; ');
      return WarehouseCopy(
        title: 'Held at $wh',
        body: 'Your parcel is on hold: $holdMsg. Our team will contact you. '
            'You cannot collect it until the hold is cleared.',
        directions: true,
      );
    case 'READY_FOR_PICKUP':
      final receiverPhone = s.receiver?.phoneMasked == true ? (s.receiver?.phone ?? '') : maskPhone(s.receiver?.phone);
      return WarehouseCopy(
        title: 'Ready for pickup',
        body: 'Collect at $wh, $address, open $hours. Bring a photo ID. '
            'We will send an OTP to the receiver ($receiverPhone) at the counter.',
        directions: true,
      );
  }
  if (s.warehouseRequired && !isTerminalState(s.state) && !prePaymentStates.contains(s.state)) {
    return WarehouseCopy(
      title: wh,
      body: 'Your parcel is being taken to $wh. We will notify you when it arrives.',
      directions: s.warehouseInfo != null,
    );
  }
  return null;
}

/// Home banner (C4).
String surchargeBannerText(ShipmentSummary s) {
  final when = s.cutoffAt == null ? 'the deadline' : formatIstDeadline(s.cutoffAt!);
  return 'Extra charge due for ${s.dcn ?? 'your parcel'} — pay ${formatInr(s.amountDuePaise)} by $when';
}
