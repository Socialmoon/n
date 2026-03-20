import 'package:flutter/material.dart';
import 'dart:async';

import '../models/member.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.currentUser,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _postingLocationController;
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _stationSuggestions = <String>[];
  Timer? _stationDebounce;
  int _stationRequest = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _postingLocationController =
        TextEditingController(text: widget.currentUser.postingLocation);
  }

  @override
  void dispose() {
    _stationDebounce?.cancel();
    _nameController.dispose();
    _postingLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Editable Basic Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postingLocationController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: _onPostingLocationChanged,
                    onTap: () =>
                        _loadStationSuggestions(_postingLocationController.text),
                    decoration: const InputDecoration(
                      labelText: 'Posting location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  _buildSuggestionChips(
                    suggestions: _stationSuggestions,
                    onSelected: (station) {
                      setState(() {
                        _postingLocationController.text = station;
                        _stationSuggestions = <String>[];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Admin Verified (Read-only)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _readOnlyRow('Mobile number', user.mobileNumber),
                  _readOnlyRow('Role', user.role),
                  _readOnlyRow('Reference mobile', user.referenceMobileNumber),
                  _readOnlyRow('Home district', user.homeDistrict),
                  _readOnlyRow('Posting district', user.postingDistrict),
                  _readOnlyRow(
                    'Appointment date',
                    '${user.appointmentDate.day}/${user.appointmentDate.month}/${user.appointmentDate.year}',
                  ),
                  _readOnlyRow(
                    'Status',
                    user.isBlocked ? 'Blocked' : 'Active',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips({
    required List<String> suggestions,
    required ValueChanged<String> onSelected,
  }) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (item) => ActionChip(
                  label: Text(item),
                  onPressed: () => onSelected(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5A6B74)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final postingLocation = _postingLocationController.text.trim();

    if (name.isEmpty) {
      _showMessage('Name cannot be empty.');
      return;
    }

    if (postingLocation.isEmpty) {
      _showMessage('Posting location cannot be empty.');
      return;
    }

    final validStation = await _locationSuggestions.isKnownStation(
      station: postingLocation,
      district: widget.currentUser.postingDistrict,
    );
    if (!validStation) {
      _showMessage('Choose a valid police station from suggestions.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final updated = widget.currentUser.copyWith(
      name: name,
      postingLocation: postingLocation,
      lastUpdated: DateTime.now(),
    );
    await widget.repository.saveMember(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    Navigator.of(context).pop(updated);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPostingLocationChanged(String value) {
    _stationDebounce?.cancel();
    _stationDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadStationSuggestions(value);
    });
  }

  Future<void> _loadStationSuggestions(String query) async {
    final request = ++_stationRequest;
    final suggestions = await _locationSuggestions.suggestPoliceStations(
      query: query,
      district: widget.currentUser.postingDistrict,
    );
    if (!mounted || request != _stationRequest) {
      return;
    }
    setState(() {
      _stationSuggestions = suggestions;
    });
  }
}
