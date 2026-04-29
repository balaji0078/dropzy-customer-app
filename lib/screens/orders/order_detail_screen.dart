import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/parcel.dart';
import '../../widgets/status_timeline.dart';
import '../../utils/helpers.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Parcel _parcel;

  @override
  void initState() {
    super.initState();
    _parcel = _generateMockParcel();
  }

  static Parcel _generateMockParcel() {
    final now = DateTime.now();
    return Parcel(
      id: '1',
      trackingId: 'DRZ100001',
      senderName: 'Rajesh Kumar',
      senderPhone: '9876543210',
      senderCity: 'Mumbai',
      receiverName: 'Priya Singh',
      receiverPhone: '9123456789',
      receiverCity: 'Delhi',
      packageType: 'Documents',
      weight: 0.5,
      status: 'In Transit',
      estimatedDelivery: now.add(const Duration(days: 2)),
      price: 299,
      createdAt: now.subtract(const Duration(hours: 5)),
      route: 'Mumbai → Delhi',
      eWayBillNo: 'EWB12345678',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTrackingHeader(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatusTimeline(
                currentStatus: _parcel.status,
                createdAt: _parcel.createdAt,
                estimatedDelivery: _parcel.estimatedDelivery,
              ),
            ),
            const SizedBox(height: 24),
            _buildParcelDetails(),
            const SizedBox(height: 24),
            _buildSenderInfo(),
            const SizedBox(height: 16),
            _buildReceiverInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingHeader() {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking ID',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _parcel.trackingId,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tracking ID copied'),
                    ),
                  );
                },
                child: Icon(
                  Icons.content_copy,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ETA',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    Helpers.formatDate(_parcel.estimatedDelivery),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(_parcel.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Helpers.getStatusBadgeText(_parcel.status),
                      style: TextStyle(
                        color: Helpers.getStatusColor(_parcel.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParcelDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parcel Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Package Type', _parcel.packageType),
              _buildDetailRow('Weight', '${_parcel.weight} kg'),
              _buildDetailRow('Price', Helpers.formatCurrency(_parcel.price)),
              _buildDetailRow('E-way Bill', _parcel.eWayBillNo ?? 'N/A'),
              _buildDetailRow('Route', _parcel.route),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sender Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', _parcel.senderName),
              _buildDetailRow('Phone', _parcel.senderPhone),
              _buildDetailRow('City', _parcel.senderCity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiverInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receiver Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Name', _parcel.receiverName),
              _buildDetailRow('Phone', _parcel.receiverPhone),
              _buildDetailRow('City', _parcel.receiverCity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_parcel.status.toLowerCase() != 'delivered' &&
              _parcel.status.toLowerCase() != 'cancelled')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Order'),
                onPressed: () {
                  _showCancelDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (_parcel.status.toLowerCase() != 'delivered' &&
              _parcel.status.toLowerCase() != 'cancelled')
            const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Contact Driver'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver contact number: +91 9876543210'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Tracking'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing tracking link...'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.of(context).pop();
                });
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
