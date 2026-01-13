// Supabase Configuration - Replace with your actual values
class AppConstants {
  // Get these from your Supabase project settings
  static const supabaseUrl = 'https://your-project-id.supabase.co';
  static const supabaseAnonKey = 'your-public-anon-key-here';
  
  // Map configuration
  static const mapStyleUrl = 'https://demotiles.maplibre.org/style.json';
  static const initialLatitude = -9.4780; // Port Moresby
  static const initialLongitude = 147.1500;
  static const initialZoom = 12.0;
  
  // Report settings
  static const reportExpiryMinutes = 15;
  
  // Common PMV routes in Port Moresby
  static const commonRoutes = [
    'Town to Gerehu',
    'Boroko to Waigani', 
    'Gordon to Koki',
    'Hohola to Downtown',
    '6 Mile to Badili',
    'Other Route'
  ];
}
