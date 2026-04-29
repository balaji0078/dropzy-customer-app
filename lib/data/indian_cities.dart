/// Bus stop / area-level pickup and drop points for Dropzy bus parcel service

class BusPoint {
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;

  const BusPoint({
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
  });

  String get displayName => '$area, $city - $pincode';
  String get shortLabel => '$area ($pincode)';
  String get cityState => '$city, $state';
}

class BusStops {
  // ─── Chennai ───
  static const List<BusPoint> chennai = [
    BusPoint(area: 'Koyambedu', city: 'Chennai', state: 'TN', pincode: '600107', lat: 13.0694, lng: 80.1948),
    BusPoint(area: 'CMBT (Koyambedu)', city: 'Chennai', state: 'TN', pincode: '600107', lat: 13.0688, lng: 80.1946),
    BusPoint(area: 'T. Nagar', city: 'Chennai', state: 'TN', pincode: '600017', lat: 13.0418, lng: 80.2341),
    BusPoint(area: 'Adyar', city: 'Chennai', state: 'TN', pincode: '600020', lat: 13.0012, lng: 80.2565),
    BusPoint(area: 'Velachery', city: 'Chennai', state: 'TN', pincode: '600042', lat: 12.9815, lng: 80.2180),
    BusPoint(area: 'Tambaram', city: 'Chennai', state: 'TN', pincode: '600045', lat: 12.9249, lng: 80.1000),
    BusPoint(area: 'Chrompet', city: 'Chennai', state: 'TN', pincode: '600044', lat: 12.9516, lng: 80.1462),
    BusPoint(area: 'Guindy', city: 'Chennai', state: 'TN', pincode: '600032', lat: 13.0067, lng: 80.2206),
    BusPoint(area: 'Anna Nagar', city: 'Chennai', state: 'TN', pincode: '600040', lat: 13.0850, lng: 80.2101),
    BusPoint(area: 'Porur', city: 'Chennai', state: 'TN', pincode: '600116', lat: 13.0382, lng: 80.1565),
    BusPoint(area: 'Palavakkam', city: 'Chennai', state: 'TN', pincode: '600041', lat: 12.9525, lng: 80.2584),
    BusPoint(area: 'Thoraipakkam', city: 'Chennai', state: 'TN', pincode: '600097', lat: 12.9345, lng: 80.2289),
    BusPoint(area: 'Sholinganallur', city: 'Chennai', state: 'TN', pincode: '600119', lat: 12.9010, lng: 80.2279),
    BusPoint(area: 'OMR (Perungudi)', city: 'Chennai', state: 'TN', pincode: '600096', lat: 12.9611, lng: 80.2394),
    BusPoint(area: 'Vadapalani', city: 'Chennai', state: 'TN', pincode: '600026', lat: 13.0499, lng: 80.2121),
    BusPoint(area: 'Egmore', city: 'Chennai', state: 'TN', pincode: '600008', lat: 13.0732, lng: 80.2609),
    BusPoint(area: 'Mylapore', city: 'Chennai', state: 'TN', pincode: '600004', lat: 13.0368, lng: 80.2676),
    BusPoint(area: 'Thiruvanmiyur', city: 'Chennai', state: 'TN', pincode: '600041', lat: 12.9830, lng: 80.2594),
    BusPoint(area: 'Avadi', city: 'Chennai', state: 'TN', pincode: '600054', lat: 13.1067, lng: 80.0970),
    BusPoint(area: 'Ambattur', city: 'Chennai', state: 'TN', pincode: '600053', lat: 13.0987, lng: 80.1574),
    BusPoint(area: 'Madhavaram', city: 'Chennai', state: 'TN', pincode: '600060', lat: 13.1482, lng: 80.2310),
    BusPoint(area: 'Perambur', city: 'Chennai', state: 'TN', pincode: '600011', lat: 13.1117, lng: 80.2450),
    BusPoint(area: 'Kilpauk', city: 'Chennai', state: 'TN', pincode: '600010', lat: 13.0840, lng: 80.2415),
    BusPoint(area: 'Nungambakkam', city: 'Chennai', state: 'TN', pincode: '600034', lat: 13.0569, lng: 80.2425),
    BusPoint(area: 'Medavakkam', city: 'Chennai', state: 'TN', pincode: '600100', lat: 12.9209, lng: 80.1924),
  ];

  // ─── Bangalore ───
  static const List<BusPoint> bangalore = [
    BusPoint(area: 'Majestic (Kempegowda)', city: 'Bangalore', state: 'KA', pincode: '560009', lat: 12.9767, lng: 77.5713),
    BusPoint(area: 'Shantinagar', city: 'Bangalore', state: 'KA', pincode: '560027', lat: 12.9556, lng: 77.5979),
    BusPoint(area: 'Silk Board', city: 'Bangalore', state: 'KA', pincode: '560068', lat: 12.9177, lng: 77.6238),
    BusPoint(area: 'Electronic City', city: 'Bangalore', state: 'KA', pincode: '560100', lat: 12.8399, lng: 77.6770),
    BusPoint(area: 'Whitefield', city: 'Bangalore', state: 'KA', pincode: '560066', lat: 12.9698, lng: 77.7500),
    BusPoint(area: 'Koramangala', city: 'Bangalore', state: 'KA', pincode: '560034', lat: 12.9279, lng: 77.6271),
    BusPoint(area: 'HSR Layout', city: 'Bangalore', state: 'KA', pincode: '560102', lat: 12.9116, lng: 77.6389),
    BusPoint(area: 'Indiranagar', city: 'Bangalore', state: 'KA', pincode: '560038', lat: 12.9784, lng: 77.6408),
    BusPoint(area: 'JP Nagar', city: 'Bangalore', state: 'KA', pincode: '560078', lat: 12.9063, lng: 77.5857),
    BusPoint(area: 'Banashankari', city: 'Bangalore', state: 'KA', pincode: '560070', lat: 12.9255, lng: 77.5468),
    BusPoint(area: 'Jayanagar', city: 'Bangalore', state: 'KA', pincode: '560041', lat: 12.9308, lng: 77.5838),
    BusPoint(area: 'Marathahalli', city: 'Bangalore', state: 'KA', pincode: '560037', lat: 12.9591, lng: 77.6974),
    BusPoint(area: 'Hebbal', city: 'Bangalore', state: 'KA', pincode: '560024', lat: 13.0358, lng: 77.5970),
    BusPoint(area: 'Yelahanka', city: 'Bangalore', state: 'KA', pincode: '560064', lat: 13.1007, lng: 77.5963),
    BusPoint(area: 'BTM Layout', city: 'Bangalore', state: 'KA', pincode: '560029', lat: 12.9166, lng: 77.6101),
    BusPoint(area: 'Rajajinagar', city: 'Bangalore', state: 'KA', pincode: '560010', lat: 12.9888, lng: 77.5525),
    BusPoint(area: 'Malleshwaram', city: 'Bangalore', state: 'KA', pincode: '560003', lat: 13.0035, lng: 77.5648),
    BusPoint(area: 'Basavanagudi', city: 'Bangalore', state: 'KA', pincode: '560004', lat: 12.9425, lng: 77.5756),
  ];

  // ─── Hyderabad ───
  static const List<BusPoint> hyderabad = [
    BusPoint(area: 'MGBS (Mahatma Gandhi)', city: 'Hyderabad', state: 'TS', pincode: '500012', lat: 17.3784, lng: 78.4866),
    BusPoint(area: 'JBS (Jubilee)', city: 'Hyderabad', state: 'TS', pincode: '500003', lat: 17.4521, lng: 78.4983),
    BusPoint(area: 'Ameerpet', city: 'Hyderabad', state: 'TS', pincode: '500016', lat: 17.4374, lng: 78.4482),
    BusPoint(area: 'Dilsukhnagar', city: 'Hyderabad', state: 'TS', pincode: '500060', lat: 17.3688, lng: 78.5247),
    BusPoint(area: 'Kukatpally', city: 'Hyderabad', state: 'TS', pincode: '500072', lat: 17.4849, lng: 78.3990),
    BusPoint(area: 'HITEC City', city: 'Hyderabad', state: 'TS', pincode: '500081', lat: 17.4435, lng: 78.3772),
    BusPoint(area: 'Secunderabad', city: 'Hyderabad', state: 'TS', pincode: '500003', lat: 17.4399, lng: 78.4983),
    BusPoint(area: 'Gachibowli', city: 'Hyderabad', state: 'TS', pincode: '500032', lat: 17.4401, lng: 78.3489),
    BusPoint(area: 'LB Nagar', city: 'Hyderabad', state: 'TS', pincode: '500074', lat: 17.3457, lng: 78.5522),
    BusPoint(area: 'Miyapur', city: 'Hyderabad', state: 'TS', pincode: '500049', lat: 17.4969, lng: 78.3548),
    BusPoint(area: 'Madhapur', city: 'Hyderabad', state: 'TS', pincode: '500081', lat: 17.4483, lng: 78.3915),
    BusPoint(area: 'Uppal', city: 'Hyderabad', state: 'TS', pincode: '500039', lat: 17.3954, lng: 78.5593),
  ];

  // ─── Mumbai ───
  static const List<BusPoint> mumbai = [
    BusPoint(area: 'Borivali', city: 'Mumbai', state: 'MH', pincode: '400066', lat: 19.2307, lng: 72.8567),
    BusPoint(area: 'Dadar', city: 'Mumbai', state: 'MH', pincode: '400014', lat: 19.0178, lng: 72.8478),
    BusPoint(area: 'Andheri', city: 'Mumbai', state: 'MH', pincode: '400058', lat: 19.1136, lng: 72.8697),
    BusPoint(area: 'Bandra', city: 'Mumbai', state: 'MH', pincode: '400050', lat: 19.0596, lng: 72.8295),
    BusPoint(area: 'Thane', city: 'Mumbai', state: 'MH', pincode: '400601', lat: 19.2183, lng: 72.9781),
    BusPoint(area: 'Vashi (Navi Mumbai)', city: 'Mumbai', state: 'MH', pincode: '400703', lat: 19.0771, lng: 72.9987),
    BusPoint(area: 'Panvel', city: 'Mumbai', state: 'MH', pincode: '410206', lat: 18.9894, lng: 73.1175),
    BusPoint(area: 'Kurla', city: 'Mumbai', state: 'MH', pincode: '400070', lat: 19.0726, lng: 72.8794),
    BusPoint(area: 'Mulund', city: 'Mumbai', state: 'MH', pincode: '400080', lat: 19.1726, lng: 72.9425),
    BusPoint(area: 'Goregaon', city: 'Mumbai', state: 'MH', pincode: '400063', lat: 19.1663, lng: 72.8526),
    BusPoint(area: 'Malad', city: 'Mumbai', state: 'MH', pincode: '400064', lat: 19.1874, lng: 72.8484),
    BusPoint(area: 'Chembur', city: 'Mumbai', state: 'MH', pincode: '400071', lat: 19.0522, lng: 72.8994),
    BusPoint(area: 'Powai', city: 'Mumbai', state: 'MH', pincode: '400076', lat: 19.1176, lng: 72.9060),
    BusPoint(area: 'Sion', city: 'Mumbai', state: 'MH', pincode: '400022', lat: 19.0394, lng: 72.8613),
  ];

  // ─── Delhi ───
  static const List<BusPoint> delhi = [
    BusPoint(area: 'ISBT Kashmere Gate', city: 'Delhi', state: 'DL', pincode: '110006', lat: 28.6679, lng: 77.2285),
    BusPoint(area: 'Anand Vihar ISBT', city: 'Delhi', state: 'DL', pincode: '110092', lat: 28.6469, lng: 77.3158),
    BusPoint(area: 'Sarai Kale Khan', city: 'Delhi', state: 'DL', pincode: '110013', lat: 28.5892, lng: 77.2525),
    BusPoint(area: 'Connaught Place', city: 'Delhi', state: 'DL', pincode: '110001', lat: 28.6315, lng: 77.2167),
    BusPoint(area: 'Nehru Place', city: 'Delhi', state: 'DL', pincode: '110019', lat: 28.5491, lng: 77.2533),
    BusPoint(area: 'Dwarka', city: 'Delhi', state: 'DL', pincode: '110075', lat: 28.5921, lng: 77.0460),
    BusPoint(area: 'Janakpuri', city: 'Delhi', state: 'DL', pincode: '110058', lat: 28.6219, lng: 77.0862),
    BusPoint(area: 'Rohini', city: 'Delhi', state: 'DL', pincode: '110085', lat: 28.7495, lng: 77.0566),
    BusPoint(area: 'Laxmi Nagar', city: 'Delhi', state: 'DL', pincode: '110092', lat: 28.6304, lng: 77.2773),
    BusPoint(area: 'Karol Bagh', city: 'Delhi', state: 'DL', pincode: '110005', lat: 28.6514, lng: 77.1907),
    BusPoint(area: 'Noida Sector 18', city: 'Delhi', state: 'DL', pincode: '201301', lat: 28.5706, lng: 77.3260),
    BusPoint(area: 'Gurgaon (IFFCO Chowk)', city: 'Delhi', state: 'DL', pincode: '122001', lat: 28.4724, lng: 77.0383),
  ];

  // ─── Pune ───
  static const List<BusPoint> pune = [
    BusPoint(area: 'Shivajinagar', city: 'Pune', state: 'MH', pincode: '411005', lat: 18.5314, lng: 73.8446),
    BusPoint(area: 'Swargate', city: 'Pune', state: 'MH', pincode: '411042', lat: 18.5018, lng: 73.8636),
    BusPoint(area: 'Wakad', city: 'Pune', state: 'MH', pincode: '411057', lat: 18.5990, lng: 73.7633),
    BusPoint(area: 'Hinjewadi', city: 'Pune', state: 'MH', pincode: '411057', lat: 18.5913, lng: 73.7389),
    BusPoint(area: 'Kothrud', city: 'Pune', state: 'MH', pincode: '411038', lat: 18.5074, lng: 73.8077),
    BusPoint(area: 'Hadapsar', city: 'Pune', state: 'MH', pincode: '411028', lat: 18.5089, lng: 73.9260),
    BusPoint(area: 'Kharadi', city: 'Pune', state: 'MH', pincode: '411014', lat: 18.5511, lng: 73.9403),
    BusPoint(area: 'Viman Nagar', city: 'Pune', state: 'MH', pincode: '411014', lat: 18.5679, lng: 73.9143),
    BusPoint(area: 'Pimpri-Chinchwad', city: 'Pune', state: 'MH', pincode: '411018', lat: 18.6298, lng: 73.7997),
    BusPoint(area: 'Baner', city: 'Pune', state: 'MH', pincode: '411045', lat: 18.5590, lng: 73.7868),
    BusPoint(area: 'Aundh', city: 'Pune', state: 'MH', pincode: '411007', lat: 18.5580, lng: 73.8073),
    BusPoint(area: 'Katraj', city: 'Pune', state: 'MH', pincode: '411046', lat: 18.4575, lng: 73.8646),
  ];

  // ─── Coimbatore ───
  static const List<BusPoint> coimbatore = [
    BusPoint(area: 'Gandhipuram', city: 'Coimbatore', state: 'TN', pincode: '641012', lat: 11.0168, lng: 76.9558),
    BusPoint(area: 'Ukkadam', city: 'Coimbatore', state: 'TN', pincode: '641001', lat: 10.9903, lng: 76.9563),
    BusPoint(area: 'Singanallur', city: 'Coimbatore', state: 'TN', pincode: '641005', lat: 10.9925, lng: 77.0274),
    BusPoint(area: 'RS Puram', city: 'Coimbatore', state: 'TN', pincode: '641002', lat: 11.0060, lng: 76.9478),
    BusPoint(area: 'Peelamedu', city: 'Coimbatore', state: 'TN', pincode: '641004', lat: 11.0242, lng: 77.0175),
    BusPoint(area: 'Saravanampatti', city: 'Coimbatore', state: 'TN', pincode: '641035', lat: 11.0712, lng: 77.0053),
    BusPoint(area: 'Sulur', city: 'Coimbatore', state: 'TN', pincode: '641401', lat: 11.0376, lng: 77.1257),
    BusPoint(area: 'Kuniyamuthur', city: 'Coimbatore', state: 'TN', pincode: '641008', lat: 10.9634, lng: 76.9412),
  ];

  // ─── Madurai ───
  static const List<BusPoint> madurai = [
    BusPoint(area: 'Mattuthavani', city: 'Madurai', state: 'TN', pincode: '625007', lat: 9.9035, lng: 78.1384),
    BusPoint(area: 'Periyar', city: 'Madurai', state: 'TN', pincode: '625001', lat: 9.9252, lng: 78.1198),
    BusPoint(area: 'Arapalayam', city: 'Madurai', state: 'TN', pincode: '625016', lat: 9.9289, lng: 78.0942),
    BusPoint(area: 'Anna Nagar', city: 'Madurai', state: 'TN', pincode: '625020', lat: 9.9503, lng: 78.1368),
    BusPoint(area: 'KK Nagar', city: 'Madurai', state: 'TN', pincode: '625020', lat: 9.9455, lng: 78.1140),
    BusPoint(area: 'Thirunagar', city: 'Madurai', state: 'TN', pincode: '625006', lat: 9.9084, lng: 78.0882),
  ];

  // ─── Kolkata ───
  static const List<BusPoint> kolkata = [
    BusPoint(area: 'Esplanade', city: 'Kolkata', state: 'WB', pincode: '700069', lat: 22.5626, lng: 88.3519),
    BusPoint(area: 'Howrah', city: 'Kolkata', state: 'WB', pincode: '711101', lat: 22.5958, lng: 88.2636),
    BusPoint(area: 'Salt Lake', city: 'Kolkata', state: 'WB', pincode: '700091', lat: 22.5804, lng: 88.4199),
    BusPoint(area: 'New Town', city: 'Kolkata', state: 'WB', pincode: '700156', lat: 22.5942, lng: 88.4830),
    BusPoint(area: 'Dum Dum', city: 'Kolkata', state: 'WB', pincode: '700028', lat: 22.6536, lng: 88.4235),
    BusPoint(area: 'Garia', city: 'Kolkata', state: 'WB', pincode: '700084', lat: 22.4604, lng: 88.3838),
    BusPoint(area: 'Barasat', city: 'Kolkata', state: 'WB', pincode: '700124', lat: 22.7226, lng: 88.4801),
    BusPoint(area: 'Park Street', city: 'Kolkata', state: 'WB', pincode: '700016', lat: 22.5521, lng: 88.3630),
  ];

  // ─── Ahmedabad ───
  static const List<BusPoint> ahmedabad = [
    BusPoint(area: 'Paldi', city: 'Ahmedabad', state: 'GJ', pincode: '380007', lat: 23.0130, lng: 72.5625),
    BusPoint(area: 'SG Highway', city: 'Ahmedabad', state: 'GJ', pincode: '380054', lat: 23.0299, lng: 72.5072),
    BusPoint(area: 'Satellite', city: 'Ahmedabad', state: 'GJ', pincode: '380015', lat: 23.0225, lng: 72.5266),
    BusPoint(area: 'Maninagar', city: 'Ahmedabad', state: 'GJ', pincode: '380008', lat: 22.9958, lng: 72.6029),
    BusPoint(area: 'Navrangpura', city: 'Ahmedabad', state: 'GJ', pincode: '380009', lat: 23.0367, lng: 72.5564),
    BusPoint(area: 'Bopal', city: 'Ahmedabad', state: 'GJ', pincode: '380058', lat: 22.9732, lng: 72.4712),
    BusPoint(area: 'Gandhinagar Highway', city: 'Ahmedabad', state: 'GJ', pincode: '382424', lat: 23.1000, lng: 72.5925),
  ];

  // ─── Jaipur ───
  static const List<BusPoint> jaipur = [
    BusPoint(area: 'Sindhi Camp', city: 'Jaipur', state: 'RJ', pincode: '302001', lat: 26.9177, lng: 75.7873),
    BusPoint(area: 'Mansarovar', city: 'Jaipur', state: 'RJ', pincode: '302020', lat: 26.8660, lng: 75.7590),
    BusPoint(area: 'Vaishali Nagar', city: 'Jaipur', state: 'RJ', pincode: '302021', lat: 26.9101, lng: 75.7371),
    BusPoint(area: 'Malviya Nagar', city: 'Jaipur', state: 'RJ', pincode: '302017', lat: 26.8552, lng: 75.8131),
    BusPoint(area: 'C-Scheme', city: 'Jaipur', state: 'RJ', pincode: '302001', lat: 26.9043, lng: 75.7904),
    BusPoint(area: 'Tonk Road', city: 'Jaipur', state: 'RJ', pincode: '302015', lat: 26.8650, lng: 75.7950),
    BusPoint(area: 'Sitapura', city: 'Jaipur', state: 'RJ', pincode: '302022', lat: 26.7863, lng: 75.8465),
  ];

  // ─── Lucknow ───
  static const List<BusPoint> lucknow = [
    BusPoint(area: 'Charbagh', city: 'Lucknow', state: 'UP', pincode: '226004', lat: 26.8467, lng: 80.9462),
    BusPoint(area: 'Hazratganj', city: 'Lucknow', state: 'UP', pincode: '226001', lat: 26.8550, lng: 80.9471),
    BusPoint(area: 'Gomti Nagar', city: 'Lucknow', state: 'UP', pincode: '226010', lat: 26.8566, lng: 80.9917),
    BusPoint(area: 'Aliganj', city: 'Lucknow', state: 'UP', pincode: '226024', lat: 26.8939, lng: 80.9461),
    BusPoint(area: 'Indira Nagar', city: 'Lucknow', state: 'UP', pincode: '226016', lat: 26.8765, lng: 80.9911),
    BusPoint(area: 'Alambagh', city: 'Lucknow', state: 'UP', pincode: '226005', lat: 26.8175, lng: 80.9187),
  ];

  // ─── All bus points combined ───
  static List<BusPoint> get all => [
    ...chennai,
    ...bangalore,
    ...hyderabad,
    ...mumbai,
    ...delhi,
    ...pune,
    ...coimbatore,
    ...madurai,
    ...kolkata,
    ...ahmedabad,
    ...jaipur,
    ...lucknow,
  ];

  /// All unique city names
  static List<String> get cities => [
    'Chennai', 'Bangalore', 'Hyderabad', 'Mumbai',
    'Delhi', 'Pune', 'Coimbatore', 'Madurai',
    'Kolkata', 'Ahmedabad', 'Jaipur', 'Lucknow',
  ];

  /// Get bus points for a specific city
  static List<BusPoint> forCity(String city) {
    switch (city) {
      case 'Chennai': return chennai;
      case 'Bangalore': return bangalore;
      case 'Hyderabad': return hyderabad;
      case 'Mumbai': return mumbai;
      case 'Delhi': return delhi;
      case 'Pune': return pune;
      case 'Coimbatore': return coimbatore;
      case 'Madurai': return madurai;
      case 'Kolkata': return kolkata;
      case 'Ahmedabad': return ahmedabad;
      case 'Jaipur': return jaipur;
      case 'Lucknow': return lucknow;
      default: return [];
    }
  }

  /// Search across all bus points by area name, city, or pincode
  static List<BusPoint> search(String query) {
    if (query.length < 2) return [];
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.area.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            p.pincode.startsWith(q))
        .take(10)
        .toList();
  }
}
