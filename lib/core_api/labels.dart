import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Visual tone of a status chip. Colour is never the only indicator: every
/// chip also has text + icon (CLIENT_CONTRACTS.md §1.10).
enum ChipTone { info, success, warning, danger, neutral }

Color toneColor(ChipTone t) {
  switch (t) {
    case ChipTone.success:
      return DropzyColors.success;
    case ChipTone.warning:
      return DropzyColors.warning;
    case ChipTone.danger:
      return DropzyColors.danger;
    case ChipTone.neutral:
      return DropzyColors.inkSoft;
    case ChipTone.info:
      return DropzyColors.info;
  }
}

class StateSpec {
  const StateSpec(this.fallbackLabel, this.icon, this.tone);

  /// §2.4 label template, used only if the API omits `stateLabel`.
  final String fallbackLabel;
  final IconData icon;
  final ChipTone tone;
}

/// CLIENT_CONTRACTS.md §2.4 — shipment state → chip icon (+ fallback label).
const Map<String, StateSpec> shipmentStateSpecs = {
  'PAYMENT_PENDING': StateSpec('Awaiting payment', Icons.schedule_rounded, ChipTone.warning),
  'PAYMENT_FAILED': StateSpec('Payment failed — retry', Icons.error_outline_rounded, ChipTone.danger),
  'EXPIRED': StateSpec('Booking expired', Icons.block_rounded, ChipTone.neutral),
  'BOOKED': StateSpec('Booked — hand over at {origin stop}', Icons.check_circle_rounded, ChipTone.success),
  'WEIGHT_CHECK_REQUIRED': StateSpec('Weighing at counter', Icons.scale_rounded, ChipTone.info),
  'WEIGHT_REVIEW': StateSpec('Weight under review', Icons.search_rounded, ChipTone.warning),
  'SURCHARGE_PAYMENT_PENDING': StateSpec('Extra weight charge due', Icons.warning_amber_rounded, ChipTone.warning),
  'READY_FOR_ORIGIN_HANDOFF': StateSpec('Ready for handover', Icons.check_circle_rounded, ChipTone.success),
  'ACCEPTED_AT_ORIGIN': StateSpec('Accepted by driver', Icons.handshake_rounded, ChipTone.info),
  'LOADED': StateSpec('Loaded on bus', Icons.directions_bus_rounded, ChipTone.info),
  'IN_TRANSIT': StateSpec('In transit', Icons.route_rounded, ChipTone.info),
  'ARRIVED_AT_DESTINATION': StateSpec('Arrived at {destination stop}', Icons.place_rounded, ChipTone.info),
  'WAREHOUSE_HOLD_UNPAID': StateSpec('Held at warehouse — payment due', Icons.lock_rounded, ChipTone.danger),
  'WAREHOUSE_HELD_OTHER': StateSpec('Held at warehouse', Icons.lock_rounded, ChipTone.warning),
  'READY_FOR_PICKUP': StateSpec('Ready for pickup', Icons.storefront_rounded, ChipTone.success),
  'DELIVERED': StateSpec('Delivered', Icons.done_all_rounded, ChipTone.success),
  'PICKED_UP': StateSpec('Picked up', Icons.done_all_rounded, ChipTone.success),
  'CANCELLED': StateSpec('Cancelled', Icons.cancel_rounded, ChipTone.danger),
  'RETURN_IN_PROGRESS': StateSpec('Returning to sender', Icons.undo_rounded, ChipTone.warning),
  'RETURNED': StateSpec('Returned to sender', Icons.undo_rounded, ChipTone.neutral),
};

const StateSpec _unknownState = StateSpec('Status updated', Icons.info_outline_rounded, ChipTone.info);

StateSpec stateSpec(String state) => shipmentStateSpecs[state] ?? _unknownState;

/// The chip text: the server's `stateLabel` verbatim; the §2.4 template is
/// only a fallback when the field is missing.
String stateLabelText(String state, String? serverLabel, {String? originStop, String? destinationStop}) {
  if (serverLabel != null && serverLabel.trim().isNotEmpty) return serverLabel.trim();
  return stateSpec(state)
      .fallbackLabel
      .replaceAll('{origin stop}', originStop ?? 'the origin stop')
      .replaceAll('{destination stop}', destinationStop ?? 'the destination');
}

/// Terminal shipment states (STATE_MACHINE.md §1). Polling stops here.
const Set<String> terminalStates = {'EXPIRED', 'DELIVERED', 'PICKED_UP', 'CANCELLED', 'RETURNED'};

/// States before a verified base-fare payment — no DCN/QR yet (C12).
const Set<String> prePaymentStates = {'PAYMENT_PENDING', 'PAYMENT_FAILED', 'EXPIRED'};

/// Parcel is in the destination warehouse inventory.
const Set<String> warehouseStates = {'WAREHOUSE_HOLD_UNPAID', 'WAREHOUSE_HELD_OTHER', 'READY_FOR_PICKUP'};

/// Parcel is at the origin counter / with the driver before loading (§6.2
/// "Load gate on and parcel at origin").
const Set<String> atOriginStates = {
  'WEIGHT_CHECK_REQUIRED',
  'WEIGHT_REVIEW',
  'SURCHARGE_PAYMENT_PENDING',
  'READY_FOR_ORIGIN_HANDOFF',
  'ACCEPTED_AT_ORIGIN',
};

bool isTerminalState(String s) => terminalStates.contains(s);

class SurchargeLabelSpec {
  const SurchargeLabelSpec(this.text, this.icon, this.tone);
  final String text;
  final IconData icon;
  final ChipTone tone;
}

/// CLIENT_CONTRACTS.md §2.5 `surcharge.customerLabel` → chip. `NONE` → null
/// (hidden). PAYMENT_FAILED added in contract rev 2.
SurchargeLabelSpec? surchargeLabelSpec(String? code) {
  switch (code) {
    case 'PAYMENT_DUE':
      return const SurchargeLabelSpec('Payment due', Icons.payments_rounded, ChipTone.warning);
    case 'VERIFYING':
      return const SurchargeLabelSpec('Verifying payment', Icons.hourglass_top_rounded, ChipTone.info);
    case 'PAID':
      return const SurchargeLabelSpec('Paid', Icons.check_circle_rounded, ChipTone.success);
    case 'WAIVED':
      return const SurchargeLabelSpec('Waived', Icons.verified_rounded, ChipTone.success);
    case 'DISPUTED':
      return const SurchargeLabelSpec('Under dispute', Icons.gavel_rounded, ChipTone.warning);
    case 'OVERDUE_WAREHOUSE':
      return const SurchargeLabelSpec('Overdue — warehouse pickup', Icons.warehouse_rounded, ChipTone.danger);
    case 'PAYMENT_FAILED':
      return const SurchargeLabelSpec('Payment failed — try again', Icons.error_outline_rounded, ChipTone.danger);
  }
  return null; // NONE / unknown → hidden
}

/// Pay is disabled for these customer labels (C11).
const Set<String> surchargeNoPayLabels = {'VERIFYING', 'PAID', 'WAIVED'};

// ─── Catalog / form labels ───

const Map<String, String> parcelCategoryLabels = {
  'DOCUMENTS': 'Documents',
  'CLOTHING': 'Clothing',
  'ELECTRONICS': 'Electronics',
  'FOOD_NON_PERISHABLE': 'Food (non-perishable)',
  'LUGGAGE': 'Luggage',
  'HOUSEHOLD': 'Household items',
  'OTHER': 'Other',
};

String categoryLabel(String code) => parcelCategoryLabels[code] ?? _titleCase(code);

/// C13 reason radio (exact copy) → DisputeCreateRequest.reasonCode.
const List<(String, String)> disputeReasons = [
  ('WEIGHT_INCORRECT', 'Weight is incorrect'),
  ('SCALE_FAULTY', 'Scale looked faulty'),
  ('ALREADY_PAID', 'I already paid'),
  ('AMOUNT_INCORRECT', 'Amount is incorrect'),
  ('OTHER', 'Other'),
];

const Map<String, String> ticketCategoryLabels = {
  'WEIGHT_DISPUTE': 'Weight dispute',
  'PAYMENT': 'Payment',
  'DAMAGE': 'Damaged parcel',
  'LOSS': 'Lost parcel',
  'DELAY': 'Delay',
  'PICKUP': 'Pickup',
  'OTHER': 'Other',
};

class TicketStatusSpec {
  const TicketStatusSpec(this.text, this.icon, this.tone);
  final String text;
  final IconData icon;
  final ChipTone tone;
}

TicketStatusSpec ticketStatusSpec(String s) {
  switch (s) {
    case 'OPEN':
      return const TicketStatusSpec('Open', Icons.mark_email_unread_rounded, ChipTone.warning);
    case 'ASSIGNED':
      return const TicketStatusSpec('Assigned', Icons.person_pin_rounded, ChipTone.info);
    case 'INVESTIGATING':
      return const TicketStatusSpec('Investigating', Icons.search_rounded, ChipTone.info);
    case 'WAITING_CUSTOMER':
      return const TicketStatusSpec('Waiting for you', Icons.reply_rounded, ChipTone.warning);
    case 'RESOLVED':
      return const TicketStatusSpec('Resolved', Icons.check_circle_rounded, ChipTone.success);
    case 'CLOSED':
      return const TicketStatusSpec('Closed', Icons.lock_outline_rounded, ChipTone.neutral);
  }
  return TicketStatusSpec(_titleCase(s), Icons.info_outline_rounded, ChipTone.info);
}

/// §6.3 hold customer messages (fallback when the hold has no
/// `customerMessage`).
const Map<String, String> holdCustomerMessages = {
  'DISPUTE': 'your dispute is being reviewed',
  'IDENTITY': "we need to verify the receiver's identity",
  'SAFETY': 'a safety check is in progress',
  'OPERATIONAL': 'an operational check is in progress',
};

// ─── Payment intents (STATE_MACHINE.md §6) ───

const Set<String> intentPendingStatuses = {'CREATED', 'REQUIRES_ACTION', 'PENDING_PROVIDER'};
const Set<String> intentFailedStatuses = {'FAILED', 'CANCELLED', 'EXPIRED'};
const Set<String> intentRefundStatuses = {'REFUND_PENDING', 'REFUNDED', 'PARTIALLY_REFUNDED'};

String _titleCase(String code) {
  final w = code.replaceAll('_', ' ').toLowerCase().trim();
  return w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}';
}
