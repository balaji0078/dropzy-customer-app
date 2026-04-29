import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/indian_cities.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/helpers.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Sender (pre-filled from logged-in user profile)
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();

  // Pickup
  String? _pickupCity;
  BusPoint? _pickupPoint;
  final _pickupAddressController = TextEditingController();

  // Receiver
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  String? _deliveryCity;
  BusPoint? _deliveryPoint;
  final _deliveryAddressController = TextEditingController();

  // Package
  String? _selectedPackageType;
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isBooking = false;
  int _currentStep = 0;

  // Package type styles
  static const Map<String, _PkgStyle> _pkgStyles = {
    'Documents': _PkgStyle(Icons.description, Color(0xFFE3F2FD), Color(0xFF1565C0)),
    'Small Parcel': _PkgStyle(Icons.inventory_2, Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    'Medium Parcel': _PkgStyle(Icons.all_inbox, Color(0xFFFFF3E0), Color(0xFFE65100)),
    'Large Parcel': _PkgStyle(Icons.widgets, Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
    'Fragile Items': _PkgStyle(Icons.warning_amber, Color(0xFFFFEBEE), Color(0xFFC62828)),
    'Food Items': _PkgStyle(Icons.restaurant, Color(0xFFFFF8E1), Color(0xFFF9A825)),
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill sender info from logged-in user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        _senderNameController.text = user.fullName;
        _senderPhoneController.text = user.phone;
        // Pre-select pickup city if user has a city set
        if (user.city.isNotEmpty && BusStops.cities.contains(user.city)) {
          setState(() => _pickupCity = user.city);
        }
      }
    });
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _pickupAddressController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _deliveryAddressController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookParcel() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupPoint == null) {
      _showError('Please select a pickup area');
      return;
    }
    if (_deliveryPoint == null) {
      _showError('Please select a delivery area');
      return;
    }
    if (_selectedPackageType == null) {
      _showError('Please select a package type');
      return;
    }
    if (_pickupPoint!.area == _deliveryPoint!.area && _pickupPoint!.city == _deliveryPoint!.city) {
      _showError('Pickup and delivery must be different');
      return;
    }

    setState(() => _isBooking = true);

    try {
      final pickupAddress = _pickupAddressController.text.isNotEmpty
          ? '${_pickupAddressController.text}, ${_pickupPoint!.area}, ${_pickupPoint!.city} ${_pickupPoint!.pincode}'
          : '${_pickupPoint!.area}, ${_pickupPoint!.city} ${_pickupPoint!.pincode}';
      final deliveryAddress = _deliveryAddressController.text.isNotEmpty
          ? '${_deliveryAddressController.text}, ${_deliveryPoint!.area}, ${_deliveryPoint!.city} ${_deliveryPoint!.pincode}'
          : '${_deliveryPoint!.area}, ${_deliveryPoint!.city} ${_deliveryPoint!.pincode}';

      final response = await _apiService.createOrder(
        pickupAddress: pickupAddress,
        pickupLat: _pickupPoint!.lat,
        pickupLng: _pickupPoint!.lng,
        deliveryAddress: deliveryAddress,
        deliveryLat: _deliveryPoint!.lat,
        deliveryLng: _deliveryPoint!.lng,
        packageType: _selectedPackageType!.toLowerCase().replaceAll(' ', '_'),
        packageWeight: double.tryParse(_weightController.text) ?? 1.0,
        receiverName: _receiverNameController.text,
        receiverPhone: _receiverPhoneController.text,
        vehicleType: 'bus',
        senderName: _senderNameController.text,
        senderPhone: _senderPhoneController.text,
        notes: _notesController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final amount = (data?['total_amount'] as num?)?.toDouble() ?? 0.0;
        final orderId = (data?['id'] ?? '').toString();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 56, color: AppTheme.green),
                ),
                const SizedBox(height: 16),
                const Text('Booking Confirmed!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Order: ${orderId.length > 8 ? '${orderId.substring(0, 8)}...' : orderId}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  Helpers.formatCurrency(amount),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_bus, size: 18, color: AppTheme.primaryRed),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${_pickupPoint!.area} → ${_deliveryPoint!.area}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkRed),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_pickupPoint!.city} → ${_deliveryPoint!.city}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('View My Orders'),
                ),
              ),
            ],
          ),
        );
      } else {
        _showError((response['message'] ?? 'Booking failed').toString());
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('401') || msg.contains('expired') || msg.contains('Unauthorized')) {
          _showError('Session expired. Please log out and log in again.');
        } else {
          _showError('Failed to book: $msg');
        }
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Parcel'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _bookParcel();
            }
          },
          onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : details.onStepContinue,
                      child: _isBooking && _currentStep == 2
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == 2 ? 'Book Now' : 'Next'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Sender & Pickup'),
              subtitle: _pickupPoint != null
                  ? Text('${_senderNameController.text.isNotEmpty ? "${_senderNameController.text} • " : ""}${_pickupPoint!.area}, ${_pickupPoint!.city}')
                  : null,
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildPickupStep(),
            ),
            Step(
              title: const Text('Receiver & Drop Point'),
              subtitle: _deliveryPoint != null
                  ? Text('${_receiverNameController.text} • ${_deliveryPoint!.area}')
                  : null,
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildReceiverStep(),
            ),
            Step(
              title: const Text('Package Details'),
              subtitle: _selectedPackageType != null
                  ? Text('$_selectedPackageType • Bus Parcel')
                  : null,
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildPackageStep(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── City + Area dropdown pair ───
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // City dropdown
        DropdownButtonFormField<String>(
          value: selectedCity,
          decoration: InputDecoration(
            labelText: cityLabel,
            prefixIcon: const Icon(Icons.location_city),
          ),
          items: BusStops.cities.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: onCityChanged,
          validator: (v) => v == null ? 'Select a city' : null,
        ),
        const SizedBox(height: 14),

        // Area / bus stop dropdown
        DropdownButtonFormField<BusPoint>(
          value: selectedPoint,
          decoration: InputDecoration(
            labelText: areaLabel,
            prefixIcon: const Icon(Icons.pin_drop),
            hintText: selectedCity == null ? 'Select city first' : 'Select area',
          ),
          items: areas.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.area, style: const TextStyle(fontSize: 14)),
                  ),
                  Text(
                    p.pincode,
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: selectedCity == null ? null : onPointChanged,
          validator: (v) => v == null ? 'Select an area' : null,
          isExpanded: true,
          menuMaxHeight: 300,
        ),

        // Show selected pincode badge
        if (selectedPoint != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.lightRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 14, color: AppTheme.green),
                const SizedBox(width: 6),
                Text(
                  '${selectedPoint.area}, ${selectedPoint.city} - ${selectedPoint.pincode}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkRed),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPickupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bus service banner
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.redGradientLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bus Parcel Service',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Send parcels via bus across 12+ cities',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sender info (pre-filled from profile)
        Text('Sender Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _senderNameController,
          decoration: const InputDecoration(
            labelText: 'Sender Name',
            hintText: 'Your full name',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _senderPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Sender Phone',
            hintText: '10-digit mobile number',
            prefixIcon: Icon(Icons.phone),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 10) return 'Enter valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Pickup location
        Text('Pickup Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _buildLocationSelector(
          cityLabel: 'Pickup City',
          areaLabel: 'Pickup Area / Bus Stop',
          selectedCity: _pickupCity,
          selectedPoint: _pickupPoint,
          onCityChanged: (city) {
            setState(() {
              _pickupCity = city;
              _pickupPoint = null;
            });
          },
          onPointChanged: (point) => setState(() => _pickupPoint = point),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _pickupAddressController,
          decoration: const InputDecoration(
            labelText: 'Street / Door No (optional)',
            hintText: 'e.g. 12/3A, 2nd Cross Street',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _receiverNameController,
          decoration: const InputDecoration(
            labelText: 'Receiver Name',
            hintText: 'Full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _receiverPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Receiver Phone',
            hintText: '10-digit mobile number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (v.length < 10) return 'Enter valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildLocationSelector(
          cityLabel: 'Delivery City',
          areaLabel: 'Drop Area / Bus Stop',
          selectedCity: _deliveryCity,
          selectedPoint: _deliveryPoint,
          onCityChanged: (city) {
            setState(() {
              _deliveryCity = city;
              _deliveryPoint = null;
            });
          },
          onPointChanged: (point) => setState(() => _deliveryPoint = point),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _deliveryAddressController,
          decoration: const InputDecoration(
            labelText: 'Delivery Address (optional)',
            hintText: 'e.g. 45, MG Road',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Package Type', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: AppConstants.packageTypes.map((type) {
            final isSelected = _selectedPackageType == type;
            final s = _pkgStyles[type] ?? _pkgStyles['Documents']!;
            return GestureDetector(
              onTap: () => setState(() => _selectedPackageType = isSelected ? null : type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? s.color : s.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? s.color : s.bg, width: 2),
                  boxShadow: isSelected
                      ? [BoxShadow(color: s.color.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s.icon, size: 28, color: isSelected ? Colors.white : s.color),
                    const SizedBox(height: 6),
                    Text(type,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : s.color,
                        )),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.check_circle, size: 16, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'Enter weight',
            prefixIcon: Icon(Icons.scale),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Required';
            if (double.tryParse(v) == null) return 'Enter valid weight';
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Bus vehicle card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.redGradientLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bus Parcel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Affordable inter-city delivery', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('DEFAULT',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Any special instructions',
            prefixIcon: Icon(Icons.note_outlined),
          ),
        ),
      ],
    );
  }
}

class _PkgStyle {
  final IconData icon;
  final Color bg;
  final Color color;
  const _PkgStyle(this.icon, this.bg, this.color);
}
