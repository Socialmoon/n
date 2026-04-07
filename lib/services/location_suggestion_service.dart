import 'dart:collection';

import 'package:flutter/services.dart';

class LocationSuggestionService {
  static const String _dataAssetPath = 'police_station_list.csv';
  static const int _defaultSuggestionLimit = 8;
  static const List<String> _states = <String>[
    'Uttar Pradesh',
    'Maharashtra',
    'Rajasthan',
    'Uttarakhand',
    'Bihar',
  ];
  static const List<String> _upDistricts = <String>[
    'Agra',
    'Aligarh',
    'Amethi',
    'Amroha',
    'Ambedkar Nagar',
    'Auraiya',
    'Ayodhya',
    'Azamgarh',
    'Bagpat',
    'Bahraich',
    'Ballia',
    'Balrampur',
    'Banda',
    'Barabanki',
    'Bareilly',
    'Basti',
    'Bijnor',
    'Budaun',
    'Bulandshahr',
    'Chandauli',
    'Chitrakoot',
    'Deoria',
    'Etah',
    'Etawah',
    'Farrukhabad',
    'Fatehpur',
    'Firozabad',
    'Gautam Buddha Nagar',
    'Ghaziabad',
    'Ghazipur',
    'Gonda',
    'Gorakhpur',
    'Hamirpur',
    'Hapur',
    'Hardoi',
    'Hathras',
    'Jalaun',
    'Jaunpur',
    'Jhansi',
    'Kannauj',
    'Kanpur Dehat',
    'Kanpur Nagar',
    'Kasganj',
    'Kaushambi',
    'Kushinagar',
    'Lakhimpur Kheri',
    'Lalitpur',
    'Lucknow',
    'Maharajganj',
    'Mahoba',
    'Mainpuri',
    'Mathura',
    'Mau',
    'Meerut',
    'Mirzapur',
    'Moradabad',
    'Muzaffarnagar',
    'Pilibhit',
    'Pratapgarh',
    'Prayagraj',
    'Rae Bareli',
    'Rampur',
    'Saharanpur',
    'Sambhal',
    'Sant Kabir Nagar',
    'Sant Ravidas Nagar (Bhadohi)',
    'Shahjahanpur',
    'Shamli',
    'Shravasti',
    'Siddharthnagar',
    'Sitapur',
    'Sonbhadra',
    'Sultanpur',
    'Unnao',
    'Varanasi',
  ];
  static const List<String> _maharashtraDistricts = <String>[
    'Ahmednagar',
    'Akola',
    'Amravati',
    'Aurangabad',
    'Beed',
    'Bhandara',
    'Buldhana',
    'Chandrapur',
    'Dhule',
    'Gadchiroli',
    'Gondia',
    'Hingoli',
    'Jalgaon',
    'Jalna',
    'Kolhapur',
    'Latur',
    'Mumbai City',
    'Mumbai Suburban',
    'Nagpur',
    'Nanded',
    'Nandurbar',
    'Nashik',
    'Osmanabad',
    'Palghar',
    'Parbhani',
    'Pune',
    'Raigad',
    'Ratnagiri',
    'Sangli',
    'Satara',
    'Sindhudurg',
    'Solapur',
    'Thane',
    'Wardha',
    'Washim',
    'Yavatmal',
  ];
  static const List<String> _rajasthanDistricts = <String>[
    'Ajmer',
    'Alwar',
    'Balotra',
    'Banswara',
    'Baran',
    'Barmer',
    'Beawar',
    'Bharatpur',
    'Bhilwara',
    'Bikaner',
    'Bundi',
    'Chittorgarh',
    'Churu',
    'Dausa',
    'Deeg',
    'Didwana-Kuchaman',
    'Dholpur',
    'Dungarpur',
    'Hanumangarh',
    'Jaipur',
    'Jaisalmer',
    'Jalore',
    'Jhalawar',
    'Jhunjhunu',
    'Jodhpur',
    'Karauli',
    'Khairthal-Tijara',
    'Kota',
    'Kotputli-Behror',
    'Nagaur',
    'Pali',
    'Phalodi',
    'Pratapgarh',
    'Rajsamand',
    'Salumbar',
    'Sawai Madhopur',
    'Sikar',
    'Sirohi',
    'Sri Ganganagar',
    'Tonk',
    'Udaipur',
  ];
  static const List<String> _uttarakhandDistricts = <String>[
    'Almora',
    'Bageshwar',
    'Chamoli',
    'Champawat',
    'Dehradun',
    'Haridwar',
    'Nainital',
    'Pauri Garhwal',
    'Pithoragarh',
    'Rudraprayag',
    'Tehri Garhwal',
    'Udham Singh Nagar',
    'Uttarkashi',
  ];
  static const List<String> _biharDistricts = <String>[
    'Araria',
    'Arwal',
    'Aurangabad',
    'Banka',
    'Begusarai',
    'Bhagalpur',
    'Bhojpur',
    'Buxar',
    'Darbhanga',
    'East Champaran',
    'Gaya',
    'Gopalganj',
    'Jamui',
    'Jehanabad',
    'Khagaria',
    'Kishanganj',
    'Kaimur',
    'Katihar',
    'Lakhisarai',
    'Madhubani',
    'Munger',
    'Madhepura',
    'Muzaffarpur',
    'Nalanda',
    'Nawada',
    'Patna',
    'Purnia',
    'Rohtas',
    'Saharsa',
    'Samastipur',
    'Sheohar',
    'Sheikhpura',
    'Saran',
    'Sitamarhi',
    'Supaul',
    'Siwan',
    'Vaishali',
    'West Champaran',
  ];
  static const Map<String, String> _districtAliases = <String, String>{
    'allahabad': 'Prayagraj',
    'faizabad': 'Ayodhya',
    'jyotiba phule nagar (amroha)': 'Amroha',
    'amroha': 'Amroha',
    'bhadohi': 'Sant Ravidas Nagar (Bhadohi)',
    'sant ravidas nagar': 'Sant Ravidas Nagar (Bhadohi)',
    'sant ravidas nagar bhadohi': 'Sant Ravidas Nagar (Bhadohi)',
    'kushi nagar': 'Kushinagar',
    'kushinagar': 'Kushinagar',
    'bulandshahar': 'Bulandshahr',
    'baghpat': 'Bagpat',
    'badaun': 'Budaun',
    'budaun': 'Budaun',
  };

  final Map<String, List<String>> _districtCache = <String, List<String>>{};
  final Map<String, List<String>> _stationCache = <String, List<String>>{};
  final Map<String, List<String>> _districtStations = <String, List<String>>{};
  final Map<String, List<String>> _districtsByState = <String, List<String>>{};
  bool _loaded = false;

  LocationSuggestionService() {
    _districtsByState['Uttar Pradesh'] = List<String>.from(_upDistricts);
    _districtsByState['Maharashtra'] = List<String>.from(_maharashtraDistricts);
    _districtsByState['Rajasthan'] = List<String>.from(_rajasthanDistricts);
    _districtsByState['Uttarakhand'] = List<String>.from(_uttarakhandDistricts);
    _districtsByState['Bihar'] = List<String>.from(_biharDistricts);
  }

  Future<List<String>> allStates({String query = ''}) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<String>.from(_states);
    }
    return _states
        .where((state) => state.toLowerCase().contains(normalized))
        .toList();
  }

  Future<List<String>> districtsForState(
    String state, {
    String query = '',
  }) async {
    final districts = _districtsByState[_canonicalStateName(state)] ?? const <String>[];
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<String>.from(districts);
    }
    return districts
        .where((district) => district.toLowerCase().contains(normalized))
        .toList();
  }

  Future<List<String>> suggestDistricts(String query) async {
    await _ensureLoaded();

    final normalized = query.trim().toLowerCase();
    final districts = _allDistricts();

    if (normalized.isEmpty) {
      return districts.take(_defaultSuggestionLimit).toList();
    }

    final cached = _districtCache[normalized];
    if (cached != null) {
      return cached;
    }

    final filtered = districts
        .where((district) => district.toLowerCase().contains(normalized))
        .take(_defaultSuggestionLimit)
        .toList();
    _districtCache[normalized] = filtered;
    return filtered;
  }

  Future<List<String>> allDistricts({String query = ''}) async {
    await _ensureLoaded();
    final normalized = query.trim().toLowerCase();
    final districts = _allDistricts();
    if (normalized.isEmpty) {
      return districts;
    }
    return districts
        .where((district) => district.toLowerCase().contains(normalized))
        .toList();
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
        ? _uniqueTop(source, limit: _defaultSuggestionLimit)
        : _uniqueTop(
            source
                .where(
                  (station) => station.toLowerCase().contains(normalizedQuery),
                )
                .toList(),
            limit: _defaultSuggestionLimit,
          );
    _stationCache[cacheKey] = results;
    return results;
  }

  Future<List<String>> allPoliceStations({
    String query = '',
    String? district,
  }) async {
    await _ensureLoaded();

    final normalizedQuery = query.trim().toLowerCase();
    final matchedDistrict = _resolveDistrict(district ?? '');
    final source = <String>[];
    if (matchedDistrict != null) {
      source.addAll(_districtStations[matchedDistrict] ?? <String>[]);
    } else {
      for (final stations in _districtStations.values) {
        source.addAll(stations);
      }
    }

    final unique = _uniqueTop(source, limit: null)..sort();
    if (normalizedQuery.isEmpty) {
      return unique;
    }
    return unique
        .where((station) => station.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  Future<List<String>> topDistricts() {
    return suggestDistricts('');
  }

  Future<List<String>> topPoliceStations({String? district}) {
    return suggestPoliceStations(query: '', district: district);
  }

  Future<bool> isKnownDistrict(String district) async {
    await _ensureLoaded();
    return _resolveDistrict(district) != null;
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

      final district = _canonicalDistrictName(columns[1].trim());
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

    for (final district in _upDistricts) {
      _districtStations.putIfAbsent(district, () => <String>[]);
    }

    for (final district in _maharashtraDistricts) {
      _districtStations.putIfAbsent(district, () => <String>[]);
    }
    for (final district in _rajasthanDistricts) {
      _districtStations.putIfAbsent(district, () => <String>[]);
    }
    for (final district in _uttarakhandDistricts) {
      _districtStations.putIfAbsent(district, () => <String>[]);
    }
    for (final district in _biharDistricts) {
      _districtStations.putIfAbsent(district, () => <String>[]);
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
    final canonical = _canonicalDistrictName(district);
    if (canonical.isEmpty) {
      return null;
    }

    final districts = _districtStations.keys;
    for (final entry in districts) {
      if (entry.toLowerCase() == canonical.toLowerCase()) {
        return entry;
      }
    }
    for (final entry in districts) {
      if (entry.toLowerCase().contains(canonical.toLowerCase())) {
        return entry;
      }
    }
    for (final entry in districts) {
      if (canonical.toLowerCase().contains(entry.toLowerCase())) {
        return entry;
      }
    }
    return null;
  }

  String _canonicalDistrictName(String district) {
    final trimmed = district.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final lower = trimmed.toLowerCase();
    final directAlias = _districtAliases[lower];
    if (directAlias != null) {
      return directAlias;
    }

    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    final normalizedAlias = _districtAliases[normalized];
    if (normalizedAlias != null) {
      return normalizedAlias;
    }

    for (final districtName in _upDistricts) {
      if (districtName.toLowerCase() == lower) {
        return districtName;
      }
      if (
          districtName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim() ==
              normalized) {
        return districtName;
      }
    }

    return trimmed;
  }

  String _canonicalStateName(String state) {
    final trimmed = state.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    for (final entry in _states) {
      if (entry.toLowerCase() == trimmed.toLowerCase()) {
        return entry;
      }
    }
    return trimmed;
  }

  List<String> _allDistricts() {
    final districts = _districtStations.keys.toList()..sort();
    return districts;
  }

  List<String> _uniqueTop(List<String> values, {int? limit}) {
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
      if (limit != null && merged.length >= limit) {
        break;
      }
    }

    return merged;
  }
}
