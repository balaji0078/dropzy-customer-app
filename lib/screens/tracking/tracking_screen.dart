import 'package:flutter/material.dart';
import '../../models/parcel.dart';
import '../../models/tracking.dart';
import '../../widgets/status_timeline.dart';
import '../../utils/helpers.dart';
import '../../config/theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _trackingController = TextEditingController();
  Parcel? _foundParcel;
  List<TrackingUpdate>? _trackingUpdates;
  bool _isSearching = false;

  static Parcel _generateMockParcel(String trackingId) {
    final now = DateTime.now();
    return Parcel(
      id: '1',
      trackingId: trackingId,
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

  static List<TrackingUpdate> _generateMockTracking() {
    final now = DateTime.now();
    return [
      TrackingUpdate(
        id: '1',
        parcelId: '1',
        status: 'Pending',
        location: 'Mumbai Sorting Center',
        lat: 19.0760,
        lng: 72.8777,
        timestamp: now.subtract(const Duration(hours: 12)),
        description: 'Parcel received at sorting center',
      ),
      TrackingUpdate(
        id: '2',
        parcelId: '1',
        status: 'Picked Up',
        location: 'Mumbai Hub',
        lat: 19.0760,
        lng: 72.8777,
        timestamp: now.subtract(const Duration(hours: 8)),
        description: 'Picked up by driver',
      ),
      TrackingUpdate(
        id: '3',
        parcelId: '1',
        status: 'In Transit',
        location: 'Nashik',
        lat: 19.9975,
        lng: 73.7898,
        timestamp: now.subtract(const Duration(hours: 3)),
        description: 'In transit to Delhi',
      ),
      TrackingUpdate(
        id: '4',
        parcelId: '1',
        status: 'In Transit',
        location: 'Agra',
        lat: 27.1767,
        lng: 78.0081,
        timestamp: now.subtract(const Duration(hours: 1)),
        description: 'Crossed Agra checkpoint',
      ),
    ];
  }

  Future<void> _searchTracking(String trackingId) async {
    if (trackingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracking ID'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _foundParcel = _generateMockParcel(trackingId);
      _trackingUpdates = _generateMockTracking();
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Parcel'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchSection(),
            if (_foundParcel != null) ...[
              const SizedBox(height: 24),
              _buildMapPlaceholder(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StatusTimeline(
                  currentStatus: _foundParcel!.status,
                  createdAt: _foundParcel!.createdAt,
                  estimatedDelivery: _foundParcel!.estimatedDelivery,
                ),
              ),
              const SizedBox(height: 24),
              _buildETACard(),
              const SizedBox(height: 24),
              _buildDriverInfoCard(),
              const SizedBox(height: 24),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Your Shipment',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _trackingController,
                  decoration: InputDecoration(
                    hintText: 'Enter tracking ID (e.g., DRZ100001)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSearching
                      ? null
                      : () {
                          _searchTracking(_trackingController.text.trim());
                        },
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Live Tracking Map',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_trackingUpdates != null && _trackingUpdates!.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Current Location: ${_trackingUpdates!.last.location}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_trackingUpdates!.last.lat}, Lng: ${_trackingUpdates!.last.lng}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              '(Map view would be displayed here)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildETACard() {
    if (_foundParcel == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDate(_foundParcel!.estimatedDelivery),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Time Remaining',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDaysRemaining(_foundParcel!.estimatedDelivery),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: 0.65,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amit Sharma',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8 (245 reviews)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calling driver: +91 9876543210'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Shipment Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a valid tracking ID to view details',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
