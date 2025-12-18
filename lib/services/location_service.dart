import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class LocationService {
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static bool get isConfigured => _apiKey.isNotEmpty;

  // Cache to avoid repeated API calls for same locations
  static final Map<String, LocationData> _cache = {};
  static const int _maxCacheSize = 100; // Limit cache size to prevent memory leaks

  static Future<LocationData?> geocodeAddress(String address) async {
    if (address.isEmpty) return null;
    
    // Check cache first
    if (_cache.containsKey(address)) {
      return _cache[address];
    }

    if (!isConfigured) {
      print('Google Maps API key not configured');
      return null;
    }

    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=$encodedAddress'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          
          final locationData = LocationData(
            latitude: location['lat'].toDouble(),
            longitude: location['lng'].toDouble(),
            formattedAddress: result['formatted_address'],
          );

          // Cache the result with size management
          _addToCache(address, locationData);
          
          return locationData;
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }

    return null;
  }

  // Fallback coordinates for common locations when API fails
  static LocationData? getFallbackLocation(String address) {
    final addressLower = address.toLowerCase();
    
    // Common city coordinates
    final fallbackLocations = {
      'new york': LocationData(latitude: 40.7128, longitude: -74.0060, formattedAddress: 'New York, NY, USA'),
      'los angeles': LocationData(latitude: 34.0522, longitude: -118.2437, formattedAddress: 'Los Angeles, CA, USA'),
      'chicago': LocationData(latitude: 41.8781, longitude: -87.6298, formattedAddress: 'Chicago, IL, USA'),
      'houston': LocationData(latitude: 29.7604, longitude: -95.3698, formattedAddress: 'Houston, TX, USA'),
      'phoenix': LocationData(latitude: 33.4484, longitude: -112.0740, formattedAddress: 'Phoenix, AZ, USA'),
      'philadelphia': LocationData(latitude: 39.9526, longitude: -75.1652, formattedAddress: 'Philadelphia, PA, USA'),
      'san antonio': LocationData(latitude: 29.4241, longitude: -98.4936, formattedAddress: 'San Antonio, TX, USA'),
      'san diego': LocationData(latitude: 32.7157, longitude: -117.1611, formattedAddress: 'San Diego, CA, USA'),
      'dallas': LocationData(latitude: 32.7767, longitude: -96.7970, formattedAddress: 'Dallas, TX, USA'),
      'san jose': LocationData(latitude: 37.3382, longitude: -121.8863, formattedAddress: 'San Jose, CA, USA'),
      'austin': LocationData(latitude: 30.2672, longitude: -97.7431, formattedAddress: 'Austin, TX, USA'),
      'seattle': LocationData(latitude: 47.6062, longitude: -122.3321, formattedAddress: 'Seattle, WA, USA'),
      'denver': LocationData(latitude: 39.7392, longitude: -104.9903, formattedAddress: 'Denver, CO, USA'),
      'washington': LocationData(latitude: 38.9072, longitude: -77.0369, formattedAddress: 'Washington, DC, USA'),
      'boston': LocationData(latitude: 42.3601, longitude: -71.0589, formattedAddress: 'Boston, MA, USA'),
      'san francisco': LocationData(latitude: 37.7749, longitude: -122.4194, formattedAddress: 'San Francisco, CA, USA'),
      'miami': LocationData(latitude: 25.7617, longitude: -80.1918, formattedAddress: 'Miami, FL, USA'),
      'atlanta': LocationData(latitude: 33.7490, longitude: -84.3880, formattedAddress: 'Atlanta, GA, USA'),
      'remote': LocationData(latitude: 39.8283, longitude: -98.5795, formattedAddress: 'Remote Work - United States'),
    };

    // Try exact match first
    if (fallbackLocations.containsKey(addressLower)) {
      return fallbackLocations[addressLower];
    }

    // Try partial matches
    for (final entry in fallbackLocations.entries) {
      if (addressLower.contains(entry.key) || entry.key.contains(addressLower)) {
        return entry.value;
      }
    }

    return null;
  }

  static Future<LocationData?> getLocationData(String address) async {
    // Try geocoding first
    final geocoded = await geocodeAddress(address);
    if (geocoded != null) return geocoded;

    // Fall back to predefined locations
    return getFallbackLocation(address);
  }

  /// MEMORY LEAK FIX: Manage cache size to prevent unlimited growth
  static void _addToCache(String address, LocationData locationData) {
    // If cache is at max size, remove oldest entry
    if (_cache.length >= _maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
      if (kDebugMode) {
        debugPrint('[LOCATION_SERVICE] Cache limit reached, removed: $firstKey');
      }
    }
    
    _cache[address] = locationData;
    if (kDebugMode) {
      debugPrint('[LOCATION_SERVICE] Cached: $address (size=${_cache.length})');
    }
  }

  /// Clear cache to free memory (useful for debugging memory issues)
  static void clearCache() {
    final cacheSize = _cache.length;
    _cache.clear();
    if (kDebugMode) {
      debugPrint('[LOCATION_SERVICE] Cache cleared, freed $cacheSize entries');
    }
  }

  /// Get current cache size (for monitoring)
  static int get cacheSize => _cache.length;
}