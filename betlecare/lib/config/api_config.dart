// lib/config/api_config.dart

class ApiConfig {
  // Base URL for all API endpoints

  static const String apiBaseUrl =
      'https://web-production-fe50.up.railway.app/api';


  // Derived API endpoints
  static String get fertilizingBasePath => '$apiBaseUrl/fertilizing';
  static String get protectionBasePath => '$apiBaseUrl/protection';
  static String get wateringBasePath => '$apiBaseUrl/watering';

  // Fertilizing endpoints
  static String get fertilizingTodayUrl => '$fertilizingBasePath/today';
  static String get fertilizingPlanUrl => '$fertilizingBasePath/plan';

  // Protection endpoints
  static String get protectionTodayUrl => '$protectionBasePath/today';
  static String get protectionPredictUrl => '$protectionBasePath/predict';
  static String get protectionConsolidatedUrl =>
      '$protectionBasePath/consolidated';

  // Watering endpoints
  static String get wateringCheckUrl => '$wateringBasePath/predict';

  // Add more endpoints as needed
}
