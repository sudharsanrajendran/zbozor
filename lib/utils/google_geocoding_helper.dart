import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class GoogleGeocodingHelper {
  static const String _apiKey = "AIzaSyCioMAZGMr91AatzOSWZiLmDSYqkvVhGDE";
  static const String _baseUrl = "https://maps.googleapis.com/maps/api/geocode/json";

  static Future<Map<String, dynamic>?> getAddress(double lat, double lng) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        _baseUrl,
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final List results = response.data['results'];
        if (results.isNotEmpty) {
          // Iterate through address components to find meaningful parts
          // We prioritize the most specific "locality" or "sublocality" logic similar to Android
          
          final components = results[0]['address_components'] as List;
          
          String? city;
          String? area;
          String? state;
          String? country;

          for (var c in components) {
            final types = (c['types'] as List).map((e) => e.toString()).toList();
            if (types.contains('locality')) {
              city = c['long_name'];
            }
            if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
              area = c['long_name'];
            }
            if (types.contains('administrative_area_level_1')) {
              state = c['long_name'];
            }
            if (types.contains('country')) {
              country = c['long_name'];
            }
          }

          // Fallback logic similar to Android's behavior observed
          // If locality is missing, use area (sublocality) as city
          if (city == null || city.isEmpty) {
             if (area != null && area.isNotEmpty) {
               city = area;
             }
          }

          return {
            'city': city,
            'area': area,
            'state': state,
            'country': country,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("GoogleGeocodingHelper Error: $e");
      }
    }
    return null;
  }
}
