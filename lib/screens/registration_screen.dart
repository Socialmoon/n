import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const List<String> _steps = <String>[
    'Identity',
    'Verify',
    'Posting',
    'Documents',
    'Review',
  ];

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _referenceController = TextEditingController();
  final _otpController = TextEditingController();
  final _homeDistrictController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingLocationController = TextEditingController();
  DateTime? _appointmentDate;
  XFile? _selfie;
  XFile? _idCardPhoto;
  Member? _referenceMember;
  int _currentStep = 0;
  String? _issuedOtp;
  bool _otpVerified = false;
  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _referenceController.dispose();
    _otpController.dispose();
    _homeDistrictController.dispose();
    _postingDistrictController.dispose();
    _postingLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFEEF4F7), Color(0xFFF7F1E7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeroHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStepStrip(),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _buildIdentityStep(),
                    _buildOtpStep(),
                    _buildPostingStep(),
                    _buildDocumentsStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF123C56), Color(0xFF2B6E78), Color(0xFFE0B36A)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'New Member Registration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete the registration in guided phases with OTP verification, posting details and document capture.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStepStrip() {
    return Row(
      children: List<Widget>.generate(_steps.length, (int index) {
        final active = index == _currentStep;
        final complete = index < _currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 8),
            child: Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: complete
                        ? const Color(0xFF2B6E78)
                        : active
                            ? const Color(0xFFE0B36A)
                            : const Color(0xFFD7E0E5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? const Color(0xFF123C56) : const Color(0xFF5A6B74),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepPage(
      title: 'Identity and referral',
      subtitle: 'Enter the member identity and confirm the referring member.',
      child: Column(
        children: <Widget>[
          _buildTextField(_nameController, 'Full name'),
          _buildTextField(
            _mobileController,
            'Mobile number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            digitsOnly: true,
            onChanged: (_) => setState(() {}),
          ),
          TextFormField(
            controller: _referenceController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
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
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EBD8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: Color(0xFF123C56),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.verified_user_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _referenceMember!.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_referenceMember!.role} • ${_referenceMember!.postingLocation}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_issuedOtp != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Demo OTP generated for testing: $_issuedOtp',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return _buildStepPage(
      title: 'OTP verification',
      subtitle: 'Verify the mobile number before continuing to posting details.',
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'OTP sent to ${_mobileController.text.trim()}. Enter the code to continue.',
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _otpController,
            'Enter OTP',
            keyboardType: TextInputType.number,
            maxLength: 6,
            digitsOnly: true,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _resendOtp,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Resend OTP'),
            ),
          ),
          if (_otpVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Mobile verification complete.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostingStep() {
    return _buildStepPage(
      title: 'Posting details',
      subtitle: 'Capture the service information that will appear in the directory.',
      child: Column(
        children: <Widget>[
          _buildTextField(_homeDistrictController, 'Home district'),
          _buildTextField(_postingDistrictController, 'Posting district'),
          _buildTextField(_postingLocationController, 'Posting location'),
          OutlinedButton.icon(
            onPressed: _pickAppointmentDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _appointmentDate == null
                  ? 'Select appointment date'
                  : 'Appointment: ${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return _buildStepPage(
      title: 'Documents and selfie',
      subtitle: 'Capture the required ID proof and selfie for the member profile.',
      child: Column(
        children: <Widget>[
          _buildUploadTile(
            title: 'Selfie photo',
            subtitle: 'Use camera capture for live verification.',
            icon: Icons.camera_alt_outlined,
            onTap: _pickSelfie,
          ),
          if (_selfie != null) _buildImagePreview(_selfie!),
          const SizedBox(height: 12),
          _buildUploadTile(
            title: 'ID card photo',
            subtitle: 'Upload the member identification card image.',
            icon: Icons.badge_outlined,
            onTap: _pickIdCardPhoto,
          ),
          if (_idCardPhoto != null) _buildImagePreview(_idCardPhoto!),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepPage(
      title: 'Review and submit',
      subtitle: 'Check the registration summary before creating the member profile.',
      child: Column(
        children: <Widget>[
          _buildSummaryRow('Full name', _nameController.text.trim()),
          _buildSummaryRow('Mobile', _mobileController.text.trim()),
          _buildSummaryRow(
            'Reference',
            _referenceMember?.name ?? _referenceController.text.trim(),
          ),
          _buildSummaryRow('Home district', _homeDistrictController.text.trim()),
          _buildSummaryRow('Posting district', _postingDistrictController.text.trim()),
          _buildSummaryRow('Posting location', _postingLocationController.text.trim()),
          _buildSummaryRow(
            'Appointment date',
            _appointmentDate == null
                ? 'Not selected'
                : '${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBD8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'After approval, the member should set an M-PIN and biometric lock in a future security settings flow.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF5A6B74), height: 1.4)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD5DEE3)),
          color: const Color(0xFFF9FBFC),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: const Color(0xFF123C56),
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF5A6B74))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile file) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FutureBuilder<Uint8List>(
          future: file.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
            if (snapshot.hasError) {
              return Container(
                height: 180,
                width: double.infinity,
                color: const Color(0xFFF3F5F7),
                alignment: Alignment.center,
                child: const Text('Preview unavailable'),
              );
            }
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF5A6B74))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: <Widget>[
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _handlePrimaryAction,
              child: Text(_currentStep == _steps.length - 1
                  ? (_submitting ? 'Registering...' : 'Submit registration')
                  : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool digitsOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: onChanged,
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

  Future<void> _pickIdCardPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() {
        _idCardPhoto = file;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentStep == 0) {
      if (!_validateIdentityStep()) {
        return;
      }
      _issuedOtp = widget.authService.issueOtp(_mobileController.text.trim());
      _otpVerified = false;
      _otpController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP generated: $_issuedOtp')),
        );
      }
      await _goToStep(1);
      return;
    }

    if (_currentStep == 1) {
      if (!_validateOtpStep()) {
        return;
      }
      _otpVerified = true;
      await _goToStep(2);
      return;
    }

    if (_currentStep == 2) {
      if (!_validatePostingStep()) {
        return;
      }
      await _goToStep(3);
      return;
    }

    if (_currentStep == 3) {
      if (!_validateDocumentsStep()) {
        return;
      }
      await _goToStep(4);
      return;
    }

    await _submit();
  }

  Future<void> _goToStep(int step) async {
    setState(() {
      _currentStep = step;
    });
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previousStep() async {
    if (_currentStep == 0) {
      return;
    }
    await _goToStep(_currentStep - 1);
  }

  void _resendOtp() {
    if (_mobileController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid mobile number first.')),
      );
      return;
    }
    _issuedOtp = widget.authService.issueOtp(_mobileController.text.trim());
    _otpVerified = false;
    _otpController.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP regenerated: $_issuedOtp')),
    );
  }

  bool _validateIdentityStep() {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final reference = _referenceController.text.trim();
    if (name.isEmpty || mobile.isEmpty || reference.isEmpty) {
      _showMessage('Enter full name, mobile number and reference mobile number.');
      return false;
    }
    if (mobile.length != 10 || reference.length != 10) {
      _showMessage('Mobile numbers must be 10 digits.');
      return false;
    }
    if (mobile == reference) {
      _showMessage('Reference mobile must be different from member mobile.');
      return false;
    }
    if (widget.repository.findByMobile(mobile) != null) {
      _showMessage('Mobile number already registered.');
      return false;
    }
    if (_referenceMember == null) {
      _showMessage('Reference member could not be verified.');
      return false;
    }
    return true;
  }

  bool _validateOtpStep() {
    final otp = _otpController.text.trim();
    if (_issuedOtp == null) {
      _showMessage('Generate OTP first.');
      return false;
    }
    if (otp.length != 6) {
      _showMessage('Enter the 6 digit OTP.');
      return false;
    }
    if (otp != _issuedOtp) {
      _showMessage('Invalid OTP.');
      return false;
    }
    return true;
  }

  bool _validatePostingStep() {
    if (_homeDistrictController.text.trim().isEmpty ||
        _postingDistrictController.text.trim().isEmpty ||
        _postingLocationController.text.trim().isEmpty) {
      _showMessage('Complete all posting details.');
      return false;
    }
    if (_appointmentDate == null) {
      _showMessage('Select the appointment date.');
      return false;
    }
    return true;
  }

  bool _validateDocumentsStep() {
    if (_selfie == null) {
      _showMessage('Upload selfie to continue.');
      return false;
    }
    if (_idCardPhoto == null) {
      _showMessage('Upload ID card photo to continue.');
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_validateIdentityStep() || !_validateOtpStep() || !_validatePostingStep() || !_validateDocumentsStep()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final now = DateTime.now();
    final mobile = _mobileController.text.trim();
    final member = Member(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      mobileNumber: mobile,
      userId: 'u_$mobile',
      passwordHash: widget.authService.hashPassword(mobile),
      mpin: '',
      referenceMobileNumber: _referenceController.text.trim(),
      referenceMemberName: _referenceMember?.name,
      selfiePath: _selfie?.path,
      idCardPhotoPath: _idCardPhoto?.path,
      homeDistrict: _homeDistrictController.text.trim(),
      postingDistrict: _postingDistrictController.text.trim(),
      postingLocation: _postingLocationController.text.trim(),
      appointmentDate: _appointmentDate!,
      role: 'Member',
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