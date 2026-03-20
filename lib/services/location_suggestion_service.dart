import 'dart:collection';

import 'package:flutter/services.dart';

class LocationSuggestionService {
  static const String _dataAssetPath = 'police_station_list.csv';

  final Map<String, List<String>> _districtCache = <String, List<String>>{};
  final Map<String, List<String>> _stationCache = <String, List<String>>{};
  final Map<String, List<String>> _districtStations = <String, List<String>>{};
  bool _loaded = false;

  Future<List<String>> suggestDistricts(String query) async {
    await _ensureLoaded();

    final normalized = query.trim().toLowerCase();
    final districts = _districtStations.keys.toList()..sort();

    if (normalized.isEmpty) {
      return districts.take(8).toList();
    }

    final cached = _districtCache[normalized];
    if (cached != null) {
      return cached;
    }

    final filtered = districts
        .where((district) => district.toLowerCase().contains(normalized))
        .take(8)
        .toList();
    _districtCache[normalized] = filtered;
    return filtered;
  }

  Future<List<String>> suggestPoliceStations({
    required String query,
    String? district,
  }) async {
    await _ensureLoaded();

    final normalizedQuery = query.trim().toLowerCase();
    final normalizedDistrict = (district ?? '').trim().toLowerCase();

    final cacheKey = '$normalizedDistrict|$normalizedQuery';
    final cached = _stationCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final matchedDistrict = _resolveDistrict(district ?? '');
    final source = <String>[];
    if (matchedDistrict != null) {
      source.addAll(_districtStations[matchedDistrict] ?? <String>[]);
    } else {
      for (final stations in _districtStations.values) {
        source.addAll(stations);
      }
    }

    final results = normalizedQuery.isEmpty
        ? _uniqueTop(source)
        : _uniqueTop(
            source
                .where(
                  (station) => station.toLowerCase().contains(normalizedQuery),
                )
                .toList(),
          );
    _stationCache[cacheKey] = results;
    return results;
  }

  Future<List<String>> topDistricts() {
    return suggestDistricts('');
  }

  Future<List<String>> topPoliceStations({String? district}) {
    return suggestPoliceStations(query: '', district: district);
  }

  Future<bool> isKnownDistrict(String district) async {
    await _ensureLoaded();
    final normalized = district.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    for (final entry in _districtStations.keys) {
      if (entry.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  Future<bool> isKnownStation({
    required String station,
    String? district,
  }) async {
    await _ensureLoaded();
    final normalizedStation = station.trim().toLowerCase();
    if (normalizedStation.isEmpty) {
      return false;
    }

    final matchedDistrict = _resolveDistrict(district ?? '');
    final source = <String>[];
    if (matchedDistrict != null) {
      source.addAll(_districtStations[matchedDistrict] ?? <String>[]);
    } else {
      for (final stations in _districtStations.values) {
        source.addAll(stations);
      }
    }

    for (final entry in source) {
      if (entry.toLowerCase() == normalizedStation) {
        return true;
      }
    }
    return false;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    final csv = await rootBundle.loadString(_dataAssetPath);
    final lines = csv.split(RegExp(r'\r?\n'));
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      final columns = _parseCsvLine(line);
      if (columns.length < 3) {
        continue;
      }

      final district = columns[1].trim();
      final station = columns[2].trim();
      if (district.isEmpty || station.isEmpty) {
        continue;
      }

      final stations =
          _districtStations.putIfAbsent(district, () => <String>[]);
      if (!stations.any((entry) => entry.toLowerCase() == station.toLowerCase())) {
        stations.add(station);
      }
    }

    for (final entry in _districtStations.entries) {
      entry.value.sort();
    }
    _loaded = true;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    result.add(buffer.toString());
    return result;
  }

  String? _resolveDistrict(String district) {
    final normalized = district.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final districts = _districtStations.keys;
    for (final entry in districts) {
      if (entry.toLowerCase() == normalized) {
        return entry;
      }
    }
    for (final entry in districts) {
      if (entry.toLowerCase().contains(normalized)) {
        return entry;
      }
    }
    return null;
  }

  List<String> _uniqueTop(List<String> values) {
    final merged = <String>[];
    final seen = HashSet<String>();

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
