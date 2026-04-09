import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:geolocator/geolocator.dart';

import '../models/member.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';

class PostingDetailsUpdateScreen extends StatefulWidget {
  const PostingDetailsUpdateScreen({
    required this.currentUser,
    required this.repository,
    required this.onUpdated,
    this.forceUpdate = false,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final ValueChanged<Member> onUpdated;
  final bool forceUpdate;

  @override
  State<PostingDetailsUpdateScreen> createState() =>
      _PostingDetailsUpdateScreenState();
}

class _PostingDetailsUpdateScreenState extends State<PostingDetailsUpdateScreen> {
  late final TextEditingController _postingStateController;
  late final TextEditingController _postingDistrictController;
  late final TextEditingController _departmentController;
  late final TextEditingController _postingCategoryController;
  late final TextEditingController _postingWorkAsController;
  late final TextEditingController _postingLocationController;
  late final TextEditingController _postingPlaceLocationController;
  bool _fetchingLocation = false;
  bool _saving = false;
  final LocationSuggestionService _locationSuggestions = LocationSuggestionService();
  List<String> _districtOptions = <String>[];
  List<String> _stationOptions = <String>[];
  List<String> _postingPlaceOptions = <String>[];
  final Map<String, GlobalKey> _fieldKeys = <String, GlobalKey>{};
  final Set<String> _invalidFieldIds = <String>{};

  static const List<String> _subDepartments = <String>[
    'Civil Police',
    'P.A.C',
    'Fire Service',
    'Jail Warden',
    'Armed Police',
    'Armed Police (AP)',
    'UPSSF',
    'GRP',
    'Dial 112',
    'LIU',
    'Radio Department',
    'Radio Police',
    'Other Unit',
    'CBCID',
    'UP ATS',
    'UP STF',
    'Sale Tax',
    'UPPCL',
    'Traffic Police',
    'Women Power Line',
    'Cyber Crime',
    'FSL',
    'Intelligence Unit',
    'Logistic',
    'Vigilance',
    'Workshop',
    'Mounted Police',
    'Anti Corruption',
    'Security Head',
    'BDS',
    'SIU',
    'AS Check Team',
    'CBI',
    'DOG Squad',
    'Others',
  ];

  static const List<String> _postingCategories = <String>[
    'Reserve Police Line',
    'LIU',
    'Police Station',
    'Fire station',
    'District Police Office Branch',
    'Other Branch/Unit office',
    'Battalion Force',
    'Range Police Office',
    'Zone Police Office',
    'Police Head Quarter office',
    'District Jail',
    'Adt. CP office',
    'Commissionerate Police office',
    'Joint CP office',
    'SP/SSP/DCP office',
    'Adt. SP/ASP/Adt. CP Office',
    'CO/ACP office',
    'DSP office',
    'RI office',
    'DCR Office',
    'CCR Office',
    'PTC',
    'PTS',
    'Police Acadmy MBD',
    'ATC',
    'Court Security',
    'PSO',
    'Other',
  ];

  static const List<String> _postingWorkOptions = <String>[
    'Field Work',
    'Office Work',
    'Court Work',
    'Gunner/PSO',
    'IC/OP',
    'SHO/SO',
    'Branch Incharge',
    'Cell Incharge',
    'Driver',
    'CO',
    'Office Incharge',
    'Other',
  ];

  static const List<String> _postingPlaceNames = <String>[
    'SPO Office',
    'Cyber Police Station',
    'Cyber Cell',
    'Mahila Thana',
    'SOG',
    'Surveillance Cell',
    'Traffic Police Office',
    'Traffic Police Line',
    'Armourer',
    'Head Clerk Branch',
    'Reader Branch',
    'Account Branch',
    'A.H.T.U.',
    'MT Branch',
    'Confidential Office',
    'Reserve Police',
    'District Fire Station',
    'Sub District Fire Station',
    'Jail Office',
    'Jail Security',
    'Anti Corruption Cell',
    'Writt Cell',
    'Writ Cell',
    'Mahila Cell',
    'Shikayat Janch Prakosth',
    'Passport Cell',
    'CCTNS Cell',
    'DCRB',
    'Narcotics Cell',
    'IGRS Cell',
    'Dispatch Cell',
    'Nyaik Samman Cell',
    'LIU',
    'Others Unit/Branch',
    'Finger print Cell',
    'Monitoring Cell',
    'Media Cell',
    'Trinetr Cell',
    'Crime Branch',
    'Police Canteen',
    'Gas Agency',
    'Jan Suchna Cell',
    'Website Cell',
    'PRO Cell',
    'Nafes Cell',
    'Interpol Cell',
    'Feedback Cell',
    'VIP Cell',
    'Election Cell',
    'Kanwar Cell',
    'EOW',
    'District Field Unit',
    'Anti Power Theft',
    'Samman Cell',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _postingStateController =
        TextEditingController(text: widget.currentUser.postingState ?? 'Uttar Pradesh');
    _postingDistrictController =
        TextEditingController(text: widget.currentUser.postingDistrict);
    _departmentController =
        TextEditingController(text: widget.currentUser.department ?? '');
    _postingCategoryController =
        TextEditingController(text: widget.currentUser.postingCategory ?? '');
    _postingWorkAsController =
        TextEditingController(text: widget.currentUser.postingWorkAs ?? '');
    _postingLocationController =
        TextEditingController(text: widget.currentUser.postingLocation);
    _postingPlaceLocationController =
        TextEditingController(text: widget.currentUser.postingPlaceLocation ?? '');
    _loadDistrictOptions();
    _loadStationOptions();
    _refreshPostingPlaceOptions();
  }

  @override
  void dispose() {
    _postingStateController.dispose();
    _postingDistrictController.dispose();
    _departmentController.dispose();
    _postingCategoryController.dispose();
    _postingWorkAsController.dispose();
    _postingLocationController.dispose();
    _postingPlaceLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadDistrictOptions() async {
    final districts = await _locationSuggestions.allDistricts();
    if (!mounted) return;
    setState(() => _districtOptions = districts);
  }

  Future<void> _loadStationOptions() async {
    final stations = await _locationSuggestions.allPoliceStations(
      district: _postingDistrictController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _stationOptions = stations);
  }

  void _refreshPostingPlaceOptions() {
    final isPoliceStation =
        _postingCategoryController.text.trim() == 'Police Station';
    setState(() {
      _postingPlaceOptions =
          isPoliceStation ? _stationOptions : List<String>.from(_postingPlaceNames);
    });
  }

  GlobalKey _fieldKey(String id) => _fieldKeys.putIfAbsent(id, () => GlobalKey());

  void _clearFieldError(String id) {
    if (!_invalidFieldIds.contains(id)) return;
    setState(() => _invalidFieldIds.remove(id));
  }

  InputDecoration _fieldDecoration(String label, {bool hasError = false, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.redAccent : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F3A4A), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      counterText: '',
      errorText: hasError ? 'Please check this field.' : null,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFD4994A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F2638)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    bool allowCustomValue = false,
    ValueChanged<String>? onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController();
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.trim().isEmpty
                ? options
                : options
                    .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setSheetState(() => query = value),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches found.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(filtered[index]),
                                  onTap: () => Navigator.of(context).pop(filtered[index]),
                                );
                              },
                            ),
                    ),
                    if (allowCustomValue)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () {
                            final typed = searchController.text.trim();
                            if (typed.isEmpty) return;
                            Navigator.of(context).pop(typed);
                          },
                          child: const Text('Use typed value'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    final selected = (result ?? '').trim();
    if (selected.isEmpty) return;
    setState(() => controller.text = selected);
    onSelected?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forceUpdate,
          title: const Text('Update Posting Details'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.forceUpdate
                      ? const Color(0xFFFFF3CD)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.forceUpdate
                        ? const Color(0xFFE5D4A1)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      widget.forceUpdate
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: widget.forceUpdate
                          ? const Color(0xFFD97706)
                          : const Color(0xFF2563EB),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.forceUpdate
                            ? 'For security and member coordination, posting details must be refreshed every 6 months. Update now to continue using the app.'
                            : 'Keep your posting details accurate so nearby members can find and contact you quickly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.forceUpdate
                              ? const Color(0xFF7A5900)
                              : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _sectionHeader('Posting Information'),
                    TextField(
                      key: _fieldKey('Posting State'),
                      controller: _postingStateController,
                      onChanged: (_) => _clearFieldError('Posting State'),
                      decoration: _fieldDecoration(
                        'Posting State',
                        hasError: _invalidFieldIds.contains('Posting State'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: _fieldKey('Posting District'),
                      onTap: () {
                        _pickFromList(
                          title: 'Select Posting District',
                          options: _districtOptions,
                          controller: _postingDistrictController,
                          allowCustomValue: true,
                          onSelected: (_) {
                            _clearFieldError('Posting District');
                            _postingLocationController.clear();
                            _loadStationOptions().then((_) => _refreshPostingPlaceOptions());
                          },
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _postingDistrictController,
                          decoration: _fieldDecoration(
                            'Posting District',
                            hint: 'Tap to choose district',
                            hasError: _invalidFieldIds.contains('Posting District'),
                          ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: _fieldKey('Sub Department'),
                      onTap: () {
                        _pickFromList(
                          title: 'Select Sub Department',
                          options: _subDepartments,
                          controller: _departmentController,
                          allowCustomValue: true,
                          onSelected: (_) => _clearFieldError('Sub Department'),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _departmentController,
                          decoration: _fieldDecoration(
                            'Sub Department',
                            hint: 'Tap to choose department',
                            hasError: _invalidFieldIds.contains('Sub Department'),
                          ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: _fieldKey('Posting Category'),
                      onTap: () {
                        _pickFromList(
                          title: 'Select Posting Category',
                          options: _postingCategories,
                          controller: _postingCategoryController,
                          allowCustomValue: true,
                          onSelected: (_) {
                            _clearFieldError('Posting Category');
                            _postingLocationController.clear();
                            _refreshPostingPlaceOptions();
                          },
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _postingCategoryController,
                          decoration: _fieldDecoration(
                            'Posting Category',
                            hint: 'Tap to choose category',
                            hasError: _invalidFieldIds.contains('Posting Category'),
                          ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: _fieldKey('Posting Work As'),
                      onTap: () {
                        _pickFromList(
                          title: 'Select Posting Work As',
                          options: _postingWorkOptions,
                          controller: _postingWorkAsController,
                          allowCustomValue: true,
                          onSelected: (_) => _clearFieldError('Posting Work As'),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _postingWorkAsController,
                          decoration: _fieldDecoration(
                            'Posting Work As',
                            hint: 'Tap to choose work type',
                            hasError: _invalidFieldIds.contains('Posting Work As'),
                          ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      key: _fieldKey('Posting Location'),
                      onTap: () {
                        _pickFromList(
                          title: _postingCategoryController.text.trim() == 'Police Station'
                              ? 'Select Posting Police Station'
                              : 'Select Posting Place Name',
                          options: _postingPlaceOptions,
                          controller: _postingLocationController,
                          allowCustomValue: true,
                          onSelected: (_) => _clearFieldError('Posting Location'),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _postingLocationController,
                          decoration: _fieldDecoration(
                            _postingCategoryController.text.trim() == 'Police Station'
                                ? 'Posting Police Station'
                                : 'Posting Place Name',
                            hint: 'Tap to choose or type',
                            hasError: _invalidFieldIds.contains('Posting Location'),
                          ).copyWith(suffixIcon: const Icon(Icons.arrow_drop_down_rounded)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _sectionHeader('GPS Location'),
                    TextField(
                      key: _fieldKey('Posting GPS'),
                      controller: _postingPlaceLocationController,
                      readOnly: true,
                      decoration: _fieldDecoration(
                        'Posting Place Location (GPS)',
                        hasError: _invalidFieldIds.contains('Posting GPS'),
                      ).copyWith(prefixIcon: const Icon(Icons.pin_drop_outlined)),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _fetchingLocation ? null : _fetchCurrentLocation,
                      icon: const Icon(Icons.my_location_outlined),
                      label: Text(
                        _fetchingLocation
                            ? 'Fetching current location...'
                            : 'Tap to share current GPS location',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFACC15),
                        foregroundColor: const Color(0xFF6B4D00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Posting Details'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _fetchingLocation = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required to continue.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _postingPlaceLocationController.text =
            '${position.latitude},${position.longitude}';
      });
      _clearFieldError('Posting GPS');
      _showMessage('Current location fetched successfully.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to fetch current location.');
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final missing = <String>[];
    void require(String fieldId, String value) {
      if (value.trim().isEmpty) missing.add(fieldId);
    }

    require('Posting State', _postingStateController.text);
    require('Posting District', _postingDistrictController.text);
    require('Sub Department', _departmentController.text);
    require('Posting Category', _postingCategoryController.text);
    require('Posting Work As', _postingWorkAsController.text);
    require('Posting Location', _postingLocationController.text);
    require('Posting GPS', _postingPlaceLocationController.text);

    if (missing.isNotEmpty) {
      setState(() {
        _invalidFieldIds
          ..clear()
          ..addAll(missing);
      });
      _showMessage('Please fill all highlighted fields.');
      _scrollToFirstInvalid(missing.first);
      return;
    }

    if (!_isAcceptableStationValue(_postingLocationController.text.trim())) {
      setState(() {
        _invalidFieldIds
          ..clear()
          ..add('Posting Location');
      });
      _showMessage('Enter a valid posting location name (3+ characters).');
      _scrollToFirstInvalid('Posting Location');
      return;
    }

    if (_postingDistrictController.text.trim().length < 2) {
      setState(() {
        _invalidFieldIds
          ..clear()
          ..add('Posting District');
      });
      _showMessage('Enter a valid district name.');
      _scrollToFirstInvalid('Posting District');
      return;
    }

    setState(() {
      _invalidFieldIds.clear();
      _saving = true;
    });

    final updated = widget.currentUser.copyWith(
      postingState: _postingStateController.text.trim(),
      postingDistrict: _postingDistrictController.text.trim(),
      department: _departmentController.text.trim(),
      postingCategory: _postingCategoryController.text.trim(),
      postingWorkAs: _postingWorkAsController.text.trim(),
      postingLocation: _postingLocationController.text.trim(),
      postingPlaceLocation: _postingPlaceLocationController.text.trim(),
      lastUpdated: DateTime.now(),
    );
    final saved = await widget.repository.saveMember(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    if (!saved) {
      _showMessage('Unable to save posting details. Please retry.');
      return;
    }

    widget.onUpdated(updated);
    _showMessage('Posting details updated successfully.');

    if (!widget.forceUpdate) {
      Navigator.of(context).pop();
    }
  }

  void _scrollToFirstInvalid(String fieldId) {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      final ctx = _fieldKeys[fieldId]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.18);
      }
    });
  }

  bool _isAcceptableStationValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return false;
    }
    return RegExp(r"^[A-Za-z0-9 .,'()/-]{3,}$").hasMatch(trimmed);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}