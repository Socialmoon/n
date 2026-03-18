import 'dart:convert';

import 'package:http/http.dart' as http;

class LocationSuggestionService {
  static const Map<String, String> _headers = <String, String>{
    'User-Agent': 'police-network-app/1.0',
    'Accept-Language': 'en',
  };

  final Map<String, List<String>> _districtCache = <String, List<String>>{};
  final Map<String, List<String>> _stationCache = <String, List<String>>{};

  Future<List<String>> suggestDistricts(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return <String>[];
    }

    final cached = _districtCache[normalized];
    if (cached != null) {
      return cached;
    }

    final live = await _fetchDistrictsFromNominatim(query);
    final unique = _uniqueTop(live);
    _districtCache[normalized] = unique;
    return unique;
  }

  Future<List<String>> suggestPoliceStations({
    required String query,
    String? district,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedDistrict = (district ?? '').trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return <String>[];
    }

    final cacheKey = '$normalizedDistrict|$normalizedQuery';
    final cached = _stationCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final live = await _fetchStationsFromNominatim(
      query: query,
      district: district,
    );

    final unique = _uniqueTop(live);
    _stationCache[cacheKey] = unique;
    return unique;
  }

  Future<List<String>> _fetchDistrictsFromNominatim(String query) async {
    final uri =
        Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
      'format': 'jsonv2',
      'countrycodes': 'in',
      'addressdetails': '1',
      'limit': '10',
      'q': '$query district india',
    });

    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <String>[];
      }

      final rows = jsonDecode(response.body) as List<dynamic>;
      final districts = <String>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }
        final address = row['address'];
        if (address is! Map<String, dynamic>) {
          continue;
        }

        final district = (address['state_district'] as String?) ??
            (address['city_district'] as String?) ??
            (address['county'] as String?) ??
            (address['state'] as String?);
        if (district != null && district.trim().isNotEmpty) {
          districts.add(district.trim());
        }
      }

      districts.sort();
      return districts.take(8).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<List<String>> _fetchStationsFromNominatim({
    required String query,
    String? district,
  }) async {
    final districtQuery = (district ?? '').trim();
    final fullQuery = districtQuery.isEmpty
        ? '$query police station india'
        : '$query police station $districtQuery india';

    final uri =
        Uri.https('nominatim.openstreetmap.org', '/search', <String, String>{
      'format': 'jsonv2',
      'countrycodes': 'in',
      'addressdetails': '1',
      'limit': '12',
      'q': fullQuery,
    });

    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <String>[];
      }

      final rows = jsonDecode(response.body) as List<dynamic>;
      final stations = <String>[];
      for (final row in rows) {
        if (row is! Map<String, dynamic>) {
          continue;
        }

        final name = (row['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          stations.add(name);
          continue;
        }

        final displayName = (row['display_name'] as String?)?.trim();
        if (displayName == null || displayName.isEmpty) {
          continue;
        }
        final first = displayName.split(',').first.trim();
        if (first.isNotEmpty) {
          stations.add(first);
        }
      }

      return stations.take(8).toList();
    } catch (_) {
      return <String>[];
    }
  }

  List<String> _uniqueTop(List<String> values) {
    final merged = <String>[];
    final seen = <String>{};

    for (final item in values) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      merged.add(trimmed);
      if (merged.length >= 8) {
        break;
      }
    }

    return merged;
  }
}
