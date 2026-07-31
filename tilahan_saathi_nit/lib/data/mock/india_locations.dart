/// Indian states and sample districts for farm setup.
abstract final class IndiaLocations {
  static const states = [
    'Andhra Pradesh',
    'Gujarat',
    'Karnataka',
    'Madhya Pradesh',
    'Maharashtra',
    'Rajasthan',
    'Tamil Nadu',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
  ];

  static const districtsByState = {
    'Andhra Pradesh': ['Anantapur', 'Guntur', 'Krishna', 'Kurnool', 'Visakhapatnam'],
    'Gujarat': ['Ahmedabad', 'Banaskantha', 'Junagadh', 'Rajkot', 'Surat'],
    'Karnataka': ['Ballari', 'Belagavi', 'Bidar', 'Dharwad', 'Kalaburagi'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Ratlam', 'Ujjain'],
    'Maharashtra': ['Akola', 'Amravati', 'Jalgaon', 'Nagpur', 'Solapur'],
    'Rajasthan': ['Ajmer', 'Bharatpur', 'Jaipur', 'Jodhpur', 'Kota'],
    'Tamil Nadu': ['Coimbatore', 'Dindigul', 'Erode', 'Salem', 'Thanjavur'],
    'Telangana': ['Hyderabad', 'Karimnagar', 'Khammam', 'Nalgonda', 'Warangal'],
    'Uttar Pradesh': ['Agra', 'Bareilly', 'Kanpur', 'Lucknow', 'Varanasi'],
    'West Bengal': ['Bankura', 'Bardhaman', 'Hooghly', 'Howrah', 'Nadia'],
  };

  static List<String> districtsFor(String? state) {
    if (state == null) return [];
    return districtsByState[state] ?? [];
  }
}

abstract final class FarmOptions {
  // These display labels map 1:1 to the backend's SoilType / WaterAvailability
  // / PlantingSeason enums via [LandApiMapping] below.
  static const soilTypes = ['Sandy', 'Loamy', 'Clay', 'Red Soil', 'Black Soil', 'Mixed'];
  static const waterOptions = ['Reliable', 'Limited', 'Rain-fed'];
  static const seasons = ['Kharif', 'Rabi', 'Summer'];
  static const currentCrops = [
    'None / Fallow',
    'Groundnut',
    'Sesame',
    'Sunflower',
    'Soybean',
    'Mustard',
    'Cotton',
    'Maize',
    'Wheat',
    'Paddy',
  ];
}

/// Maps [FarmOptions] display labels to the exact enum values the backend's
/// `POST /lands` endpoint expects (see `LandCreate` in the OpenAPI schema).
abstract final class LandApiMapping {
  static const soilType = {
    'Sandy': 'sandy',
    'Loamy': 'loamy',
    'Clay': 'clay',
    'Red Soil': 'red_soil',
    'Black Soil': 'black_soil',
    'Mixed': 'mixed',
  };

  static const waterAvailability = {
    'Reliable': 'reliable',
    'Limited': 'limited',
    'Rain-fed': 'rain_fed',
  };

  static const plantingSeason = {
    'Kharif': 'kharif',
    'Rabi': 'rabi',
    'Summer': 'summer',
  };
}
