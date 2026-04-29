class AppConstants {
  static const String appName = 'Dropzy';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'http://18.60.129.43:8080/api/v1';
  static const String defaultCurrency = 'INR';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String ordersEndpoint = '/orders';
  static const String driversNearbyEndpoint = '/drivers/nearby';
  static const String userProfileEndpoint = '/users/profile';
  static const String notificationsEndpoint = '/notifications';
  static const String paymentsEndpoint = '/payments';
  static const String pricingEstimateEndpoint = '/pricing/estimate';
  static const String ratesEstimateEndpoint = '/rates/estimate';
  static const String trackingOrderEndpoint = '/tracking/order';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  // Parcel Status
  static const List<String> parcelStatuses = [
    'Pending',
    'Picked Up',
    'In Transit',
    'Out for Delivery',
    'Delivered',
    'Cancelled'
  ];

  // Package Types
  static const List<String> packageTypes = [
    'Documents',
    'Small Parcel',
    'Medium Parcel',
    'Large Parcel',
    'Fragile Items',
    'Food Items'
  ];

  // Indian Cities
  static const List<String> indianCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Lucknow',
    'Chandigarh',
    'Indore'
  ];

  // Notification Types
  static const String notificationTypeBooking = 'booking';
  static const String notificationTypeTransit = 'transit';
  static const String notificationTypeDelivery = 'delivery';
  static const String notificationTypePayment = 'payment';
}
