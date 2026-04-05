import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import '../models/member.dart';
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
  late final TextEditingController _postingLocationController;
  late final TextEditingController _postingPlaceLocationController;
  bool _fetchingLocation = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _postingLocationController =
        TextEditingController(text: widget.currentUser.postingLocation);
    _postingPlaceLocationController =
        TextEditingController(text: widget.currentUser.postingPlaceLocation ?? '');
  }

  @override
  void dispose() {
    _postingLocationController.dispose();
    _postingPlaceLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.forceUpdate,
          title: const Text('Update Posting Details'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                color: const Color(0xFFFFF3CD),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    widget.forceUpdate
                        ? 'For security and member coordination, posting details must be refreshed every 6 months. Update now to continue using the app.'
                        : 'Keep your posting details accurate so nearby members can find and contact you quickly.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _postingLocationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Posting Location',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _postingPlaceLocationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Posting Place Location (GPS)',
                  prefixIcon: Icon(Icons.pin_drop_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _fetchingLocation ? null : _fetchCurrentLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(
                    _fetchingLocation
                        ? 'Fetching current location...'
                        : 'Use current location',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save Posting Details'),
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
    final postingLocation = _postingLocationController.text.trim();
    final postingPlaceLocation = _postingPlaceLocationController.text.trim();

    if (postingLocation.isEmpty) {
      _showMessage('Posting location is required.');
      return;
    }
    if (!_isAcceptableStationValue(postingLocation)) {
      _showMessage('Enter a valid posting location name.');
      return;
    }
    if (postingPlaceLocation.isEmpty) {
      _showMessage('Posting place GPS location is required.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final updated = widget.currentUser.copyWith(
      postingLocation: postingLocation,
      postingPlaceLocation: postingPlaceLocation,
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