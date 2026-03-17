import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/member_repository.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    required this.repository,
    required this.authService,
    super.key,
  });

  final MemberRepository repository;
  final AuthService authService;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _referenceController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mpinController = TextEditingController();
  final _homeDistrictController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingLocationController = TextEditingController();
  final _roleController = TextEditingController();
  DateTime? _appointmentDate;
  XFile? _selfie;
  Member? _referenceMember;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _referenceController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    _mpinController.dispose();
    _homeDistrictController.dispose();
    _postingDistrictController.dispose();
    _postingLocationController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Registration')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            _buildTextField(_nameController, 'Full name'),
            _buildTextField(
              _mobileController,
              'Mobile number',
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            TextFormField(
              controller: _referenceController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Reference member mobile number',
              ),
              onChanged: (value) {
                setState(() {
                  _referenceMember = widget.repository.findByMobile(value.trim());
                });
              },
            ),
            if (_referenceMember != null)
              Card(
                color: const Color(0xFFF6EFE2),
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(_referenceMember!.name),
                  subtitle: Text(
                    '${_referenceMember!.role} • ${_referenceMember!.postingLocation}',
                  ),
                ),
              ),
            _buildTextField(_userIdController, 'User ID'),
            _buildTextField(
              _passwordController,
              'Password',
              obscureText: true,
            ),
            _buildTextField(
              _mpinController,
              '6 digit M-PIN',
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
            ),
            _buildTextField(_homeDistrictController, 'Home district'),
            _buildTextField(_postingDistrictController, 'Posting district'),
            _buildTextField(_postingLocationController, 'Posting location'),
            _buildTextField(_roleController, 'Role / designation'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickAppointmentDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _appointmentDate == null
                    ? 'Select appointment date'
                    : 'Appointment: ${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickSelfie,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_selfie == null ? 'Upload selfie' : 'Replace selfie'),
            ),
            if (_selfie != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_selfie!.path),
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Registering...' : 'Complete registration'),
            ),
            const SizedBox(height: 12),
            const Text(
              'The first install already contains a seeded admin member with mobile 9000000000 and M-PIN 123456 for bootstrap access.',
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _pickAppointmentDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialDate: _appointmentDate ?? DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _appointmentDate = selected;
      });
    }
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 65);
    if (file != null) {
      setState(() {
        _selfie = file;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_appointmentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the appointment date.')),
      );
      return;
    }
    if (widget.repository.findByMobile(_mobileController.text.trim()) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile number already registered.')),
      );
      return;
    }
    if (_referenceController.text.trim().isNotEmpty && _referenceMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reference member could not be verified.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final now = DateTime.now();
    final member = Member(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      userId: _userIdController.text.trim(),
      passwordHash: widget.authService.hashPassword(_passwordController.text.trim()),
      mpin: _mpinController.text.trim(),
      referenceMobileNumber: _referenceController.text.trim(),
      referenceMemberName: _referenceMember?.name,
      selfiePath: _selfie?.path,
      homeDistrict: _homeDistrictController.text.trim(),
      postingDistrict: _postingDistrictController.text.trim(),
      postingLocation: _postingLocationController.text.trim(),
      appointmentDate: _appointmentDate!,
      role: _roleController.text.trim(),
      lastUpdated: now,
      passwordUpdatedAt: now,
    );
    await widget.repository.saveMember(member);

    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    Navigator.of(context).pop(member);
  }
}