import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/parcel.dart';
import 'status_badge.dart';
import '../utils/helpers.dart';

class ParcelCard extends StatelessWidget {
  final Parcel parcel;
  final VoidCallback onTap;

  const ParcelCard({
    Key? key,
    required this.parcel,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryRed,
              width: 4,
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receiver name + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.lightRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              parcel.receiverName.isNotEmpty
                                  ? parcel.receiverName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryRed,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parcel.receiverName.isNotEmpty
                                    ? parcel.receiverName
                                    : 'Unknown',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parcel.receiverPhone,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: parcel.status),
                ],
              ),
              const SizedBox(height: 12),
              // Route
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, size: 14, color: AppTheme.primaryRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${parcel.senderCity} → ${parcel.receiverCity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkRed,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Weight, package type, price, date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${parcel.weight}kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        parcel.packageType.isNotEmpty
                            ? parcel.packageType.replaceAll('_', ' ')
                            : 'Parcel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    Helpers.formatCurrency(parcel.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                Helpers.formatDate(parcel.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
