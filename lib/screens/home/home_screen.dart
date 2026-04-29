import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/parcel.dart';
import '../../services/api_service.dart';
import '../../widgets/parcel_card.dart';
import '../orders/orders_screen.dart';
import '../tracking/tracking_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Parcel> _recentParcels = [];
  bool _isLoadingParcels = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchRecentOrders();
  }

  Future<void> _fetchRecentOrders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final rawResponse = await _apiService.get('/orders?page=1&limit=5', token: token);

      if (rawResponse is Map<String, dynamic>) {
        final data = rawResponse['data'];
        List<dynamic> ordersList = [];

        if (data is Map<String, dynamic> && data.containsKey('orders')) {
          ordersList = data['orders'] as List<dynamic>? ?? [];
        } else if (data is List) {
          ordersList = data;
        }

        if (mounted) {
          final parcels = ordersList
              .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
              .toList();
          // Sort latest first
          parcels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          setState(() {
            _recentParcels = parcels;
            _isLoadingParcels = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingParcels = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const OrdersScreen();
      case 2:
        return const TrackingScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 32),
            _buildActiveShipmentsSection(),
            const SizedBox(height: 32),
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userName = authProvider.user?.firstName ?? 'User';
        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.redGradientLight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "India's Most Trusted Parcel Service",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your shipments instantly',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.add_box_outlined,
              label: 'Book Parcel',
              onTap: () {
                Navigator.of(context).pushNamed('/booking');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.search,
              label: 'Track Parcel',
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.calculate,
              label: 'Estimate Cost',
              onTap: () {
                Navigator.of(context).pushNamed('/estimator');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveShipmentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Shipments',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingParcels)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_recentParcels.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text('No shipments yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).pushNamed('/booking');
                      if (result == true) _fetchRecentOrders();
                    },
                    child: const Text('Book Your First Parcel'),
                  ),
                ],
              ),
            )
          else
            ..._recentParcels
                .where((p) => p.status.toLowerCase() != 'delivered')
                .take(2)
                .map(
                  (parcel) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ParcelCard(
                      parcel: parcel,
                      onTap: () {
                        Navigator.of(context).pushNamed('/order-detail');
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.check_circle_outline,
            title: 'Parcel Delivered',
            description: 'Your parcel DRZ100000 was delivered',
            time: '2 hours ago',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.local_shipping,
            title: 'Out for Delivery',
            description: 'Parcel DRZ100001 is out for delivery',
            time: '30 minutes ago',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.notifications_active,
            title: 'New Offer',
            description: 'Get 20% off on your next shipment',
            time: '1 day ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
