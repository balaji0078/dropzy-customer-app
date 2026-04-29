import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Helpers.getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Helpers.getStatusColor(status),
          width: 1,
        ),
      ),
      child: Text(
        Helpers.getStatusBadgeText(status),
        style: TextStyle(
          color: Helpers.getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
