import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../data/indian_cities.dart';
import '../../widgets/custom_button.dart';
import '../../utils/helpers.dart';

class EstimatorScreen extends StatefulWidget {
  const EstimatorScreen({Key? key}) : super(key: key);

  @override
  State<EstimatorScreen> createState() => _EstimatorScreenState();
}

class _EstimatorScreenState extends State<EstimatorScreen> {
  String? _originCity;
  BusPoint? _originPoint;
  String? _destCity;
  BusPoint? _destPoint;
  String? _selectedPackageType;
  final _weightController = TextEditingController();
  bool _isCalculating = false;
  Map<String, dynamic>? _estimateResult;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _calculateEstimate() async {
    if (_originPoint == null || _destPoint == null ||
        _selectedPackageType == null || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_originPoint!.area == _destPoint!.area && _originPoint!.city == _destPoint!.city) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin and destination must be different')),
      );
      return;
    }

    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(seconds: 1));

    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final basePrice = 150.0;
    final distanceFactor = 50.0;
    final weightFactor = weight * 20.0;
    final packageMultiplier = _getPackageMultiplier(_selectedPackageType!);
    final estimatedPrice = (basePrice + distanceFactor + weightFactor) * packageMultiplier;
    final gst = estimatedPrice * 0.18;
    final totalPrice = estimatedPrice + gst;

    setState(() {
      _estimateResult = {
        'basePrice': estimatedPrice,
        'gst': gst,
        'totalPrice': totalPrice,
        'deliveryDays': _originCity == _destCity ? 1 : 2,
      };
      _isCalculating = false;
    });
  }

  double _getPackageMultiplier(String packageType) {
    switch (packageType) {
      case 'Documents': return 0.5;
      case 'Small Parcel': return 1.0;
      case 'Medium Parcel': return 1.5;
      case 'Large Parcel': return 2.0;
      case 'Fragile Items': return 2.5;
      case 'Food Items': return 1.8;
      default: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Estimator'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculate Shipping Cost', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Enter details to get an instant quote', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),

            // Pickup
            _buildLocationSelector(
              cityLabel: 'Pickup City',
              areaLabel: 'Pickup Area',
              selectedCity: _originCity,
              selectedPoint: _originPoint,
              onCityChanged: (c) => setState(() { _originCity = c; _originPoint = null; }),
              onPointChanged: (p) => setState(() => _originPoint = p),
            ),
            const SizedBox(height: 16),

            // Delivery
            _buildLocationSelector(
              cityLabel: 'Delivery City',
              areaLabel: 'Delivery Area',
              selectedCity: _destCity,
              selectedPoint: _destPoint,
              onCityChanged: (c) => setState(() { _destCity = c; _destPoint = null; }),
              onPointChanged: (p) => setState(() => _destPoint = p),
            ),
            const SizedBox(height: 24),

            Text('Package Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.packageTypes.map((type) {
                final isSelected = _selectedPackageType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (sel) => setState(() => _selectedPackageType = sel ? type : null),
                  selectedColor: AppTheme.primaryRed.withAlpha(77),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Text('Weight (in kg)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter weight',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(text: 'Calculate Estimate', onPressed: _calculateEstimate, isLoading: _isCalculating),

            if (_estimateResult != null) ...[
              const SizedBox(height: 32),
              _buildResultCard(),
              const SizedBox(height: 16),
              CustomButton(text: 'Book Now', onPressed: () => Navigator.of(context).pushNamed('/booking')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String cityLabel,
    required String areaLabel,
    required String? selectedCity,
    required BusPoint? selectedPoint,
    required ValueChanged<String?> onCityChanged,
    required ValueChanged<BusPoint?> onPointChanged,
  }) {
    final areas = selectedCity != null ? BusStops.forCity(selectedCity) : <BusPoint>[];
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedCity,
          decoration: InputDecoration(
            labelText: cityLabel,
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: BusStops.cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: onCityChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BusPoint>(
          value: selectedPoint,
          decoration: InputDecoration(
            labelText: areaLabel,
            prefixIcon: const Icon(Icons.pin_drop),
            hintText: selectedCity == null ? 'Select city first' : 'Select area',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: areas.map((p) => DropdownMenuItem(
            value: p,
            child: Row(
              children: [
                Expanded(child: Text(p.area, style: const TextStyle(fontSize: 14))),
                Text(p.pincode, style: const TextStyle(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
              ],
            ),
          )).toList(),
          onChanged: selectedCity == null ? null : onPointChanged,
          isExpanded: true,
          menuMaxHeight: 300,
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildPriceRow('Base Fare', Helpers.formatCurrency(_estimateResult!['basePrice'])),
            const SizedBox(height: 8),
            _buildPriceRow('GST (18%)', Helpers.formatCurrency(_estimateResult!['gst'])),
            const Divider(height: 16),
            _buildPriceRow('Total', Helpers.formatCurrency(_estimateResult!['totalPrice']), isBold: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_originPoint?.area ?? ''} → ${_destPoint?.area ?? ''} • ~${_estimateResult!['deliveryDays']} days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium),
        Text(amount, style: isBold
            ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primaryRed)
            : Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
