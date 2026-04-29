import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class Helpers {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return formatter.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA500);
      case 'picked up':
        return const Color(0xFF4285F4);
      case 'in transit':
        return const Color(0xFF0F9D58);
      case 'out for delivery':
        return const Color(0xFF34A853);
      case 'delivered':
        return const Color(0xFF188038);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'picked up':
        return Icons.local_shipping;
      case 'in transit':
        return Icons.directions_car;
      case 'out for delivery':
        return Icons.location_searching;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\D'), ''));
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(value)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhone(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String getStatusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'picked up':
        return 'Picked Up';
      case 'in transit':
        return 'In Transit';
      case 'out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static int getStatusIndex(String status) {
    final statusList = [
      'pending',
      'picked up',
      'in transit',
      'out for delivery',
      'delivered'
    ];
    return statusList.indexWhere(
      (s) => s.toLowerCase() == status.toLowerCase(),
    );
  }

  static Duration calculateDaysRemaining(DateTime estimatedDelivery) {
    return estimatedDelivery.difference(DateTime.now());
  }

  static String formatDaysRemaining(DateTime estimatedDelivery) {
    final difference = calculateDaysRemaining(estimatedDelivery);
    if (difference.isNegative) {
      return 'Delivered';
    }
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    if (days > 0) {
      return '$days day${days > 1 ? 's' : ''} remaining';
    }
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} remaining';
    }
    return 'Due soon';
  }
}
