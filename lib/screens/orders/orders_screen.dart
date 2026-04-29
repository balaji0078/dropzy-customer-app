import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/parcel.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/parcel_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'Active';
  List<Parcel> _allParcels = [];
  bool _isLoading = true;
  String? _error;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getOrders();
      if (mounted) {
        // Sort latest first
        response.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() {
          _allParcels = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If API fails, try parsing orders from raw GET
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        final rawResponse = await _apiService.get('/orders?page=1&limit=50', token: token);

        if (rawResponse is Map<String, dynamic>) {
          final data = rawResponse['data'];
          List<dynamic> ordersList = [];

          if (data is Map<String, dynamic> && data.containsKey('orders')) {
            ordersList = data['orders'] as List<dynamic>? ?? [];
          } else if (data is List) {
            ordersList = data;
          } else if (rawResponse.containsKey('orders')) {
            ordersList = rawResponse['orders'] as List<dynamic>? ?? [];
          }

          if (mounted) {
            setState(() {
              _allParcels = ordersList
                  .map((item) => Parcel.fromJson(item as Map<String, dynamic>))
                  .toList();
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Parcel> _getFilteredParcels() {
    switch (_selectedFilter) {
      case 'Active':
        return _allParcels
            .where((p) =>
                p.status.toLowerCase() != 'delivered' &&
                p.status.toLowerCase() != 'cancelled')
            .toList();
      case 'Delivered':
        return _allParcels
            .where((p) => p.status.toLowerCase() == 'delivered')
            .toList();
      case 'Cancelled':
        return _allParcels
            .where((p) => p.status.toLowerCase() == 'cancelled')
            .toList();
      default:
        return _allParcels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredParcels = _getFilteredParcels();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Could not load orders',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _fetchOrders,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredParcels.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text('No $_selectedFilter orders',
                                    style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilter == 'Active'
                                      ? 'Book a parcel to get started!'
                                      : 'No $_selectedFilter shipments yet',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (_selectedFilter == 'Active') ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.of(context)
                                          .pushNamed('/booking');
                                      if (result == true) _fetchOrders();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Book Parcel'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredParcels.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ParcelCard(
                                    parcel: filteredParcels[index],
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushNamed('/order-detail');
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/booking');
          if (result == true) _fetchOrders();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: ['Active', 'Delivered', 'Cancelled'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  filter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
