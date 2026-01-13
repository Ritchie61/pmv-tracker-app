// Configuration file for app constants and API keys
class AppConstants {
  // TODO: REPLACE WITH YOUR SUPABASE PROJECT CREDENTIALS
  // Get these from: Supabase Project Settings > API
  static const supabaseUrl = 'https://your-project-id.supabase.co';
  static const supabaseAnonKey = 'your-public-anon-key-here';

  // Map settings
  static const mapStyleUrl =
      'https://demotiles.maplibre.org/style.json'; // Free map tiles
  static const initialLatitude = -9.4780; // Port Moresby coordinates
  static const initialLongitude = 147.1500;
  static const initialZoom = 12.0;

  // PMV Report settings
  static const reportExpiryMinutes = 15;

  // Common PMV routes in Port Moresby
  static const commonRoutes = [
    'Town to Gerehu',
    'Boroko to Waigani',
    'Gordon to Koki',
    'Hohola to Downtown',
    '6 Mile to Badili',
    'Other Route',
  ];
}
