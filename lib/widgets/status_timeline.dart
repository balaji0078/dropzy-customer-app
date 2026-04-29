import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final DateTime createdAt;
  final DateTime estimatedDelivery;

  const StatusTimeline({
    Key? key,
    required this.currentStatus,
    required this.createdAt,
    required this.estimatedDelivery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusList = [
      'Pending',
      'Picked Up',
      'In Transit',
      'Out for Delivery',
      'Delivered'
    ];

    final currentIndex = Helpers.getStatusIndex(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Shipment Status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statusList.length,
          itemBuilder: (context, index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFE0E0E0),
                        ),
                        child: Center(
                          child: Icon(
                            Helpers.getStatusIcon(statusList[index]),
                            color: isCompleted ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      if (index < statusList.length - 1)
                        Container(
                          width: 2,
                          height: 60,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFE0E0E0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusList[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (index == 0)
                            Text(
                              Helpers.formatDateTime(createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else if (index == statusList.length - 1 && !isCompleted)
                            Text(
                              'Expected: ${Helpers.formatDate(estimatedDelivery)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else if (isCompleted && index != 0)
                            Text(
                              'Completed',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
