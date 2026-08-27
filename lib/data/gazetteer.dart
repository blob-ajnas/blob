/// The single source of truth for every place name the app will accept.
///
/// Two requirements meet here, and that is deliberate:
///
///  * Signup must offer **dropdowns only**, so an invalid or misspelt place can
///    never be stored.
///  * Every place shown in the UI must be **pinnable on a map**.
///
/// Both are satisfied by one rule: a place is selectable *only if* it carries
/// coordinates. Keeping the list and the coordinates in the same records makes
/// the two properties impossible to separate — you cannot add a district to the
/// dropdown without also giving the map somewhere to point, and a name that is
/// not in here cannot be entered at all, so there is no such thing as a stored
/// place the map cannot find.
///
/// Scope: Karnataka is filled in to city level because that is where BLOB
/// operates. Other Indian states are present at state level so users elsewhere
/// can still register, and [countries] covers exporters and foreign investors.
library;

/// A place with a fixed position. [lat]/[lng] are the map pin.
class Place {
  const Place(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;

  @override
  String toString() => name;
}

/// A district and the cities/towns inside it.
class District {
  const District(this.place, this.cities);

  final Place place;
  final List<Place> cities;

  String get name => place.name;
}

/// A state (or union territory) and its districts.
class StateRegion {
  const StateRegion(this.place, this.districts);

  final Place place;
  final List<District> districts;

  String get name => place.name;
}

class Gazetteer {
  Gazetteer._();

  /// Where a map should sit when we have no place at all: centred on India.
  static const Place indiaCentre = Place('India', 22.5937, 78.9629);

  /// Karnataka, to city level — BLOB's operating region.
  static const StateRegion karnataka = StateRegion(
    Place('Karnataka', 15.3173, 75.7139),
    [
      District(Place('Mandya', 12.5223, 76.8954), [
        Place('Mandya', 12.5223, 76.8954),
        Place('Maddur', 12.5847, 77.0454),
        Place('Malavalli', 12.3852, 77.0611),
        Place('Nagamangala', 12.8180, 76.7550),
        Place('Pandavapura', 12.5030, 76.6660),
        Place('Srirangapatna', 12.4181, 76.6947),
        Place('Krishnarajpet', 12.6690, 76.4870),
      ]),
      District(Place('Mysuru', 12.2958, 76.6394), [
        Place('Mysuru', 12.2958, 76.6394),
        Place('Nanjangud', 12.1180, 76.6830),
        Place('Hunsur', 12.3040, 76.2930),
        Place('Periyapatna', 12.3350, 76.1000),
        Place('T. Narasipura', 12.2100, 76.9000),
        Place('Krishnarajanagara', 12.4270, 76.3880),
      ]),
      District(Place('Hassan', 13.0072, 76.0962), [
        Place('Hassan', 13.0072, 76.0962),
        Place('Arsikere', 13.3140, 76.2570),
        Place('Channarayapatna', 12.9060, 76.3880),
        Place('Sakleshpur', 12.9420, 75.7860),
        Place('Belur', 13.1660, 75.8660),
        Place('Holenarasipura', 12.7890, 76.2450),
      ]),
      District(Place('Bengaluru Urban', 12.9716, 77.5946), [
        Place('Bengaluru', 12.9716, 77.5946),
        Place('Yelahanka', 13.1007, 77.5963),
        Place('Whitefield', 12.9698, 77.7500),
        Place('Anekal', 12.7110, 77.6960),
      ]),
      District(Place('Bengaluru Rural', 13.2257, 77.5750), [
        Place('Devanahalli', 13.2437, 77.7115),
        Place('Doddaballapura', 13.2960, 77.5370),
        Place('Hoskote', 13.0707, 77.7980),
        Place('Nelamangala', 13.0990, 77.3940),
      ]),
      District(Place('Tumakuru', 13.3392, 77.1010), [
        Place('Tumakuru', 13.3392, 77.1010),
        Place('Tiptur', 13.2560, 76.4770),
        Place('Sira', 13.7440, 76.9040),
        Place('Madhugiri', 13.6620, 77.2100),
        Place('Kunigal', 13.0230, 77.0250),
      ]),
      District(Place('Belagavi', 15.8497, 74.4977), [
        Place('Belagavi', 15.8497, 74.4977),
        Place('Chikkodi', 16.4260, 74.5920),
        Place('Gokak', 16.1670, 74.8230),
        Place('Bailhongal', 15.8140, 74.8600),
      ]),
      District(Place('Ballari', 15.1394, 76.9214), [
        Place('Ballari', 15.1394, 76.9214),
        Place('Hosapete', 15.2690, 76.3870),
        Place('Sandur', 15.1000, 76.5470),
      ]),
      District(Place('Kalaburagi', 17.3297, 76.8343), [
        Place('Kalaburagi', 17.3297, 76.8343),
        Place('Sedam', 17.1830, 77.2830),
        Place('Chittapur', 17.1220, 77.0830),
      ]),
      District(Place('Dakshina Kannada', 12.8438, 75.2479), [
        Place('Mangaluru', 12.9141, 74.8560),
        Place('Puttur', 12.7590, 75.2010),
        Place('Bantwal', 12.8900, 75.0350),
      ]),
      District(Place('Udupi', 13.3409, 74.7421), [
        Place('Udupi', 13.3409, 74.7421),
        Place('Kundapura', 13.6260, 74.6920),
        Place('Karkala', 13.2160, 74.9930),
      ]),
      District(Place('Shivamogga', 13.9299, 75.5681), [
        Place('Shivamogga', 13.9299, 75.5681),
        Place('Bhadravati', 13.8480, 75.7050),
        Place('Sagara', 14.1660, 75.0330),
      ]),
      District(Place('Davanagere', 14.4644, 75.9218), [
        Place('Davanagere', 14.4644, 75.9218),
        Place('Harihar', 14.5130, 75.8020),
        Place('Channagiri', 14.0240, 75.9260),
      ]),
      District(Place('Dharwad', 15.4589, 75.0078), [
        Place('Dharwad', 15.4589, 75.0078),
        Place('Hubballi', 15.3647, 75.1240),
        Place('Kalghatgi', 15.1830, 74.9670),
      ]),
      District(Place('Chikkamagaluru', 13.3161, 75.7720), [
        Place('Chikkamagaluru', 13.3161, 75.7720),
        Place('Kadur', 13.5510, 76.0110),
        Place('Mudigere', 13.1350, 75.6400),
      ]),
      District(Place('Kodagu', 12.3375, 75.8069), [
        Place('Madikeri', 12.4200, 75.7400),
        Place('Virajpet', 12.1960, 75.8050),
        Place('Somwarpet', 12.5960, 75.8500),
      ]),
      District(Place('Chitradurga', 14.2251, 76.3980), [
        Place('Chitradurga', 14.2251, 76.3980),
        Place('Hiriyur', 13.9450, 76.6180),
        Place('Challakere', 14.3170, 76.6520),
      ]),
      District(Place('Kolar', 13.1357, 78.1325), [
        Place('Kolar', 13.1357, 78.1325),
        Place('Chikkaballapura', 13.4350, 77.7280),
        Place('Bangarapet', 12.9910, 78.1780),
      ]),
      District(Place('Raichur', 16.2076, 77.3463), [
        Place('Raichur', 16.2076, 77.3463),
        Place('Sindhanur', 15.7680, 76.7550),
        Place('Manvi', 15.9900, 77.0500),
      ]),
      District(Place('Vijayapura', 16.8302, 75.7100), [
        Place('Vijayapura', 16.8302, 75.7100),
        Place('Indi', 17.1770, 75.9500),
        Place('Basavana Bagevadi', 16.5730, 75.9700),
      ]),
      District(Place('Bagalkot', 16.1691, 75.6615), [
        Place('Bagalkot', 16.1691, 75.6615),
        Place('Jamkhandi', 16.5050, 75.2900),
        Place('Badami', 15.9150, 75.6770),
      ]),
      District(Place('Haveri', 14.7951, 75.4041), [
        Place('Haveri', 14.7951, 75.4041),
        Place('Ranebennur', 14.6210, 75.6290),
        Place('Hirekerur', 14.4500, 75.3900),
      ]),
      District(Place('Gadag', 15.4315, 75.6355), [
        Place('Gadag', 15.4315, 75.6355),
        Place('Ron', 15.6960, 75.7370),
        Place('Naragund', 15.7250, 75.3900),
      ]),
      District(Place('Bidar', 17.9104, 77.5199), [
        Place('Bidar', 17.9104, 77.5199),
        Place('Bhalki', 17.8700, 77.2000),
        Place('Basavakalyan', 17.8750, 76.9500),
      ]),
      District(Place('Koppal', 15.3500, 76.1547), [
        Place('Koppal', 15.3500, 76.1547),
        Place('Gangavathi', 15.4300, 76.5300),
        Place('Yelbarga', 15.6170, 76.0170),
      ]),
      District(Place('Yadgir', 16.7700, 77.1376), [
        Place('Yadgir', 16.7700, 77.1376),
        Place('Shahapur', 16.6980, 76.8420),
        Place('Surpur', 16.5170, 76.7580),
      ]),
      District(Place('Chamarajanagar', 11.9236, 76.9456), [
        Place('Chamarajanagar', 11.9236, 76.9456),
        Place('Kollegal', 12.1540, 77.1100),
        Place('Gundlupet', 11.8110, 76.6900),
      ]),
      District(Place('Ramanagara', 12.7217, 77.2800), [
        Place('Ramanagara', 12.7217, 77.2800),
        Place('Channapatna', 12.6510, 77.2070),
        Place('Kanakapura', 12.5460, 77.4200),
      ]),
      District(Place('Uttara Kannada', 14.7935, 74.6869), [
        Place('Karwar', 14.8135, 74.1297),
        Place('Sirsi', 14.6200, 74.8360),
        Place('Bhatkal', 13.9850, 74.5550),
      ]),
      District(Place('Vijayanagara', 15.2690, 76.3870), [
        Place('Hosapete', 15.2690, 76.3870),
        Place('Hampi', 15.3350, 76.4600),
        Place('Kudligi', 14.9070, 76.3860),
      ]),
    ],
  );

  /// Every Indian state and union territory. Only [karnataka] is expanded to
  /// district/city level; the rest carry a single district so the dropdown
  /// chain always resolves and the map always has a pin.
  static const List<StateRegion> states = [
    karnataka,
    StateRegion(Place('Andhra Pradesh', 15.9129, 79.7400), [
      District(Place('Visakhapatnam', 17.6868, 83.2185), [
        Place('Visakhapatnam', 17.6868, 83.2185),
      ]),
      District(Place('Vijayawada', 16.5062, 80.6480), [
        Place('Vijayawada', 16.5062, 80.6480),
      ]),
      District(Place('Guntur', 16.3067, 80.4365), [
        Place('Guntur', 16.3067, 80.4365),
      ]),
    ]),
    StateRegion(Place('Arunachal Pradesh', 28.2180, 94.7278), [
      District(Place('Itanagar', 27.0844, 93.6053), [
        Place('Itanagar', 27.0844, 93.6053),
      ]),
    ]),
    StateRegion(Place('Assam', 26.2006, 92.9376), [
      District(Place('Kamrup', 26.1445, 91.7362), [
        Place('Guwahati', 26.1445, 91.7362),
      ]),
      District(Place('Dibrugarh', 27.4728, 94.9120), [
        Place('Dibrugarh', 27.4728, 94.9120),
      ]),
    ]),
    StateRegion(Place('Bihar', 25.0961, 85.3131), [
      District(Place('Patna', 25.5941, 85.1376), [
        Place('Patna', 25.5941, 85.1376),
      ]),
      District(Place('Gaya', 24.7955, 85.0002), [
        Place('Gaya', 24.7955, 85.0002),
      ]),
    ]),
    StateRegion(Place('Chhattisgarh', 21.2787, 81.8661), [
      District(Place('Raipur', 21.2514, 81.6296), [
        Place('Raipur', 21.2514, 81.6296),
      ]),
    ]),
    StateRegion(Place('Goa', 15.2993, 74.1240), [
      District(Place('North Goa', 15.5000, 73.8300), [
        Place('Panaji', 15.4909, 73.8278),
      ]),
      District(Place('South Goa', 15.1000, 74.0000), [
        Place('Margao', 15.2832, 73.9862),
      ]),
    ]),
    StateRegion(Place('Gujarat', 22.2587, 71.1924), [
      District(Place('Ahmedabad', 23.0225, 72.5714), [
        Place('Ahmedabad', 23.0225, 72.5714),
      ]),
      District(Place('Surat', 21.1702, 72.8311), [
        Place('Surat', 21.1702, 72.8311),
      ]),
    ]),
    StateRegion(Place('Haryana', 29.0588, 76.0856), [
      District(Place('Gurugram', 28.4595, 77.0266), [
        Place('Gurugram', 28.4595, 77.0266),
      ]),
      District(Place('Faridabad', 28.4089, 77.3178), [
        Place('Faridabad', 28.4089, 77.3178),
      ]),
    ]),
    StateRegion(Place('Himachal Pradesh', 31.1048, 77.1734), [
      District(Place('Shimla', 31.1048, 77.1734), [
        Place('Shimla', 31.1048, 77.1734),
      ]),
    ]),
    StateRegion(Place('Jharkhand', 23.6102, 85.2799), [
      District(Place('Ranchi', 23.3441, 85.3096), [
        Place('Ranchi', 23.3441, 85.3096),
      ]),
    ]),
    StateRegion(Place('Kerala', 10.8505, 76.2711), [
      District(Place('Ernakulam', 9.9816, 76.2999), [
        Place('Kochi', 9.9312, 76.2673),
      ]),
      District(Place('Thiruvananthapuram', 8.5241, 76.9366), [
        Place('Thiruvananthapuram', 8.5241, 76.9366),
      ]),
      District(Place('Kozhikode', 11.2588, 75.7804), [
        Place('Kozhikode', 11.2588, 75.7804),
      ]),
    ]),
    StateRegion(Place('Madhya Pradesh', 22.9734, 78.6569), [
      District(Place('Indore', 22.7196, 75.8577), [
        Place('Indore', 22.7196, 75.8577),
      ]),
      District(Place('Bhopal', 23.2599, 77.4126), [
        Place('Bhopal', 23.2599, 77.4126),
      ]),
    ]),
    StateRegion(Place('Maharashtra', 19.7515, 75.7139), [
      District(Place('Mumbai', 19.0760, 72.8777), [
        Place('Mumbai', 19.0760, 72.8777),
      ]),
      District(Place('Pune', 18.5204, 73.8567), [
        Place('Pune', 18.5204, 73.8567),
      ]),
      District(Place('Nagpur', 21.1458, 79.0882), [
        Place('Nagpur', 21.1458, 79.0882),
      ]),
    ]),
    StateRegion(Place('Manipur', 24.6637, 93.9063), [
      District(Place('Imphal West', 24.8170, 93.9368), [
        Place('Imphal', 24.8170, 93.9368),
      ]),
    ]),
    StateRegion(Place('Meghalaya', 25.4670, 91.3662), [
      District(Place('East Khasi Hills', 25.5788, 91.8933), [
        Place('Shillong', 25.5788, 91.8933),
      ]),
    ]),
    StateRegion(Place('Mizoram', 23.1645, 92.9376), [
      District(Place('Aizawl', 23.7271, 92.7176), [
        Place('Aizawl', 23.7271, 92.7176),
      ]),
    ]),
    StateRegion(Place('Nagaland', 26.1584, 94.5624), [
      District(Place('Kohima', 25.6751, 94.1086), [
        Place('Kohima', 25.6751, 94.1086),
      ]),
    ]),
    StateRegion(Place('Odisha', 20.9517, 85.0985), [
      District(Place('Khordha', 20.2961, 85.8245), [
        Place('Bhubaneswar', 20.2961, 85.8245),
      ]),
      District(Place('Cuttack', 20.4625, 85.8830), [
        Place('Cuttack', 20.4625, 85.8830),
      ]),
    ]),
    StateRegion(Place('Punjab', 31.1471, 75.3412), [
      District(Place('Ludhiana', 30.9010, 75.8573), [
        Place('Ludhiana', 30.9010, 75.8573),
      ]),
      District(Place('Amritsar', 31.6340, 74.8723), [
        Place('Amritsar', 31.6340, 74.8723),
      ]),
    ]),
    StateRegion(Place('Rajasthan', 27.0238, 74.2179), [
      District(Place('Jaipur', 26.9124, 75.7873), [
        Place('Jaipur', 26.9124, 75.7873),
      ]),
      District(Place('Jodhpur', 26.2389, 73.0243), [
        Place('Jodhpur', 26.2389, 73.0243),
      ]),
    ]),
    StateRegion(Place('Sikkim', 27.5330, 88.5122), [
      District(Place('Gangtok', 27.3389, 88.6065), [
        Place('Gangtok', 27.3389, 88.6065),
      ]),
    ]),
    StateRegion(Place('Tamil Nadu', 11.1271, 78.6569), [
      District(Place('Chennai', 13.0827, 80.2707), [
        Place('Chennai', 13.0827, 80.2707),
      ]),
      District(Place('Coimbatore', 11.0168, 76.9558), [
        Place('Coimbatore', 11.0168, 76.9558),
      ]),
      District(Place('Madurai', 9.9252, 78.1198), [
        Place('Madurai', 9.9252, 78.1198),
      ]),
    ]),
    StateRegion(Place('Telangana', 18.1124, 79.0193), [
      District(Place('Hyderabad', 17.3850, 78.4867), [
        Place('Hyderabad', 17.3850, 78.4867),
      ]),
      District(Place('Warangal', 17.9689, 79.5941), [
        Place('Warangal', 17.9689, 79.5941),
      ]),
    ]),
    StateRegion(Place('Tripura', 23.9408, 91.9882), [
      District(Place('West Tripura', 23.8315, 91.2868), [
        Place('Agartala', 23.8315, 91.2868),
      ]),
    ]),
    StateRegion(Place('Uttar Pradesh', 26.8467, 80.9462), [
      District(Place('Lucknow', 26.8467, 80.9462), [
        Place('Lucknow', 26.8467, 80.9462),
      ]),
      District(Place('Kanpur Nagar', 26.4499, 80.3319), [
        Place('Kanpur', 26.4499, 80.3319),
      ]),
      District(Place('Varanasi', 25.3176, 82.9739), [
        Place('Varanasi', 25.3176, 82.9739),
      ]),
    ]),
    StateRegion(Place('Uttarakhand', 30.0668, 79.0193), [
      District(Place('Dehradun', 30.3165, 78.0322), [
        Place('Dehradun', 30.3165, 78.0322),
      ]),
    ]),
    StateRegion(Place('West Bengal', 22.9868, 87.8550), [
      District(Place('Kolkata', 22.5726, 88.3639), [
        Place('Kolkata', 22.5726, 88.3639),
      ]),
      District(Place('Darjeeling', 27.0360, 88.2627), [
        Place('Darjeeling', 27.0360, 88.2627),
      ]),
    ]),
    StateRegion(Place('Delhi', 28.7041, 77.1025), [
      District(Place('New Delhi', 28.6139, 77.2090), [
        Place('New Delhi', 28.6139, 77.2090),
      ]),
    ]),
    StateRegion(Place('Jammu and Kashmir', 33.7782, 76.5762), [
      District(Place('Srinagar', 34.0837, 74.7973), [
        Place('Srinagar', 34.0837, 74.7973),
      ]),
      District(Place('Jammu', 32.7266, 74.8570), [
        Place('Jammu', 32.7266, 74.8570),
      ]),
    ]),
    StateRegion(Place('Ladakh', 34.1526, 77.5771), [
      District(Place('Leh', 34.1526, 77.5771), [
        Place('Leh', 34.1526, 77.5771),
      ]),
    ]),
    StateRegion(Place('Puducherry', 11.9416, 79.8083), [
      District(Place('Puducherry', 11.9416, 79.8083), [
        Place('Puducherry', 11.9416, 79.8083),
      ]),
    ]),
    StateRegion(Place('Chandigarh', 30.7333, 76.7794), [
      District(Place('Chandigarh', 30.7333, 76.7794), [
        Place('Chandigarh', 30.7333, 76.7794),
      ]),
    ]),
    StateRegion(Place('Andaman and Nicobar Islands', 11.7401, 92.6586), [
      District(Place('South Andaman', 11.6234, 92.7265), [
        Place('Port Blair', 11.6234, 92.7265),
      ]),
    ]),
    StateRegion(Place('Dadra and Nagar Haveli and Daman and Diu', 20.1809,
        73.0169), [
      District(Place('Daman', 20.3974, 72.8328), [
        Place('Daman', 20.3974, 72.8328),
      ]),
    ]),
    StateRegion(Place('Lakshadweep', 10.5667, 72.6417), [
      District(Place('Kavaratti', 10.5593, 72.6358), [
        Place('Kavaratti', 10.5593, 72.6358),
      ]),
    ]),
  ];

  /// Countries for exporters and foreign investors. India is first because it
  /// is the common case; the rest are BLOB's main trade partners.
  static const List<Place> countries = [
    Place('India', 22.5937, 78.9629),
    Place('United Arab Emirates', 23.4241, 53.8478),
    Place('Saudi Arabia', 23.8859, 45.0792),
    Place('Qatar', 25.3548, 51.1839),
    Place('Kuwait', 29.3117, 47.4818),
    Place('Oman', 21.4735, 55.9754),
    Place('Bahrain', 25.9304, 50.6378),
    Place('United States', 37.0902, -95.7129),
    Place('United Kingdom', 55.3781, -3.4360),
    Place('Canada', 56.1304, -106.3468),
    Place('Australia', -25.2744, 133.7751),
    Place('Singapore', 1.3521, 103.8198),
    Place('Malaysia', 4.2105, 101.9758),
    Place('Germany', 51.1657, 10.4515),
    Place('Netherlands', 52.1326, 5.2913),
    Place('France', 46.2276, 2.2137),
    Place('Japan', 36.2048, 138.2529),
    Place('China', 35.8617, 104.1954),
    Place('Bangladesh', 23.6850, 90.3563),
    Place('Sri Lanka', 7.8731, 80.7718),
    Place('Nepal', 28.3949, 84.1240),
    Place('Vietnam', 14.0583, 108.2772),
    Place('Thailand', 15.8700, 100.9925),
    Place('Indonesia', -0.7893, 113.9213),
    Place('South Africa', -30.5595, 22.9375),
    Place('Kenya', -0.0236, 37.9062),
    Place('Brazil', -14.2350, -51.9253),
    Place('Russia', 61.5240, 105.3188),
    Place('Italy', 41.8719, 12.5674),
    Place('Spain', 40.4637, -3.7492),
  ];

  // ---- Lookups ----------------------------------------------------------
  // Built once, lazily. Everything the UI shows goes through these, so a name
  // that is not in the gazetteer simply has no position and no map link.

  static final Map<String, Place> _byName = _buildIndex();

  static Map<String, Place> _buildIndex() {
    final index = <String, Place>{};
    // Least specific first, so a more specific place of the same name wins:
    // "Mysuru" should resolve to the city, not the district centroid.
    for (final country in countries) {
      index[_key(country.name)] = country;
    }
    for (final state in states) {
      index[_key(state.name)] = state.place;
      for (final district in state.districts) {
        index[_key(district.name)] = district.place;
      }
    }
    for (final state in states) {
      for (final district in state.districts) {
        for (final city in district.cities) {
          index[_key(city.name)] = city;
        }
      }
    }
    return index;
  }

  static String _key(String name) => name.trim().toLowerCase();

  /// Resolves a stored place name to coordinates, or null if unknown.
  ///
  /// Returns null rather than a fallback position on purpose: callers use null
  /// to decide *not* to offer a map link, which is better than dropping a pin
  /// in the wrong place and asserting it is correct.
  static Place? lookup(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final direct = _byName[_key(trimmed)];
    if (direct != null) return direct;
    // Stored values are sometimes composite, e.g. "Maddur, Mandya". Try the
    // most specific component first.
    for (final part in trimmed.split(',')) {
      final hit = _byName[_key(part)];
      if (hit != null) return hit;
    }
    return null;
  }

  /// True when [name] can be pinned on a map.
  static bool isKnown(String? name) => lookup(name) != null;

  static List<String> get stateNames =>
      states.map((s) => s.name).toList(growable: false);

  static StateRegion? state(String? name) {
    if (name == null) return null;
    for (final s in states) {
      if (_key(s.name) == _key(name)) return s;
    }
    return null;
  }

  /// Districts within [stateName], alphabetically.
  static List<String> districtsIn(String? stateName) {
    final s = state(stateName);
    if (s == null) return const [];
    final names = s.districts.map((d) => d.name).toList()..sort();
    return names;
  }

  /// Cities within a district, alphabetically.
  static List<String> citiesIn(String? stateName, String? districtName) {
    final s = state(stateName);
    if (s == null || districtName == null) return const [];
    for (final d in s.districts) {
      if (_key(d.name) == _key(districtName)) {
        final names = d.cities.map((c) => c.name).toList()..sort();
        return names;
      }
    }
    return const [];
  }

  /// The state a district belongs to — used to back-fill the state dropdown
  /// for accounts created before state was collected.
  static String? stateOfDistrict(String? districtName) {
    if (districtName == null) return null;
    for (final s in states) {
      for (final d in s.districts) {
        if (_key(d.name) == _key(districtName)) return s.name;
      }
    }
    return null;
  }

  static List<String> get countryNames =>
      countries.map((c) => c.name).toList(growable: false);

  /// Place names matching [query], for type-ahead fields where a strict
  /// dropdown would be wrong — a lorry pickup point can legitimately be a
  /// warehouse or a landmark, not just a town. Suggesting gazetteer names
  /// steers people onto mappable spellings without blocking the rest.
  ///
  /// Prefix matches rank above substring matches so typing "man" offers
  /// "Mandya" before "Chikkamagaluru".
  static List<String> search(String query, {int limit = 8}) {
    final q = _key(query);
    if (q.isEmpty) return const [];
    final prefix = <String>[];
    final contains = <String>[];
    for (final entry in _byName.entries) {
      if (entry.key.startsWith(q)) {
        prefix.add(entry.value.name);
      } else if (entry.key.contains(q)) {
        contains.add(entry.value.name);
      }
      if (prefix.length >= limit) break;
    }
    prefix.sort();
    contains.sort();
    return [...prefix, ...contains].take(limit).toList(growable: false);
  }
}
