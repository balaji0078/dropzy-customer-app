import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _generateMockNotifications();
  }

  static List<NotificationModel> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        title: 'Parcel Delivered',
        body: 'Your parcel DRZ100000 has been successfully delivered',
        type: AppConstants.notificationTypeDelivery,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
        parcelId: 'DRZ100000',
      ),
      NotificationModel(
        id: '2',
        title: 'Out for Delivery',
        body: 'Your parcel DRZ100001 is out for delivery',
        type: AppConstants.notificationTypeTransit,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        parcelId: 'DRZ100001',
      ),
      NotificationModel(
        id: '3',
        title: 'Booking Confirmed',
        body: 'Your new parcel booking has been confirmed',
        type: AppConstants.notificationTypeBooking,
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 5)),
        parcelId: 'DRZ100002',
      ),
      NotificationModel(
        id: '4',
        title: 'Payment Successful',
        body: 'Payment of INR 299 has been processed successfully',
        type: AppConstants.notificationTypePayment,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        parcelId: 'DRZ100001',
      ),
      NotificationModel(
        id: '5',
        title: 'In Transit',
        body: 'Your parcel DRZ100003 is in transit',
        type: AppConstants.notificationTypeTransit,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        parcelId: 'DRZ100003',
      ),
      NotificationModel(
        id: '6',
        title: 'Special Offer',
        body: 'Get 25% off on your next 3 shipments!',
        type: AppConstants.notificationTypeBooking,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
        parcelId: null,
      ),
    ];
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var i = 0; i < _notifications.length; i++) {
                    _notifications[i] = _notifications[i].copyWith(isRead: true);
                  }
                });
              },
              child: const Text(
                'Mark All as Read',
                style: TextStyle(color: AppTheme.primaryRed),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationTile(notification),
                );
              },
            ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) {
        _deleteNotification(notification.id);
      },
      child: Card(
        child: InkWell(
          onTap: () {
            _markAsRead(notification);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: notification.isRead
                  ? Colors.white
                  : AppTheme.lightRed,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNotificationColor(notification.type).withOpacity(0.2),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Helpers.formatTime(notification.createdAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'read',
                      child: const Text('Mark as read'),
                      onTap: () {
                        _markAsRead(notification);
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: const Text('Delete'),
                      onTap: () {
                        _deleteNotification(notification.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case AppConstants.notificationTypeDelivery:
        return Colors.green;
      case AppConstants.notificationTypeTransit:
        return Colors.orange;
      case AppConstants.notificationTypeBooking:
        return Colors.blue;
      case AppConstants.notificationTypePayment:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case AppConstants.notificationTypeDelivery:
        return Icons.check_circle_outline;
      case AppConstants.notificationTypeTransit:
        return Icons.local_shipping;
      case AppConstants.notificationTypeBooking:
        return Icons.shopping_bag_outlined;
      case AppConstants.notificationTypePayment:
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }
}
