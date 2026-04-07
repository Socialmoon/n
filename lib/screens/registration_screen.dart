// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/email_otp_service.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';
import 'terms_privacy_screen.dart';

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
  static const Color _ink = Color(0xFF1E2A36);
  static const Color _accent = Color(0xFFB08A53);
  static const Color _panel = Color(0xFFFCFAF5);
  static const Color _border = Color(0xFFE1D8C8);

  static const List<String> _steps = <String>[
    'Basic Detail',
    'Verify Self Email',
    'Verify Referral Email',
    'Posting Details',
    'Home Details',
    'Photos',
    'Review',
  ];

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailOtpController = TextEditingController();
  final _mpinController = TextEditingController();
  final _referenceController = TextEditingController();
  final _referenceEmailController = TextEditingController();
  final _referenceEmailOtpController = TextEditingController();
  final _departmentController = TextEditingController();
  final _departmentOtherController = TextEditingController();
  final _postRankController = TextEditingController();
  final _customRankController = TextEditingController();
  final _genderController = TextEditingController();
  final _genderOtherController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _maritalStatusOtherController = TextEditingController();
  final _postingCategoryController = TextEditingController();
  final _postingCategoryOtherController = TextEditingController();
  final _postingWorkAsController = TextEditingController();
  final _postingWorkAsOtherController = TextEditingController();
  final _homeStateController = TextEditingController(text: 'Uttar Pradesh');
  final _homeStateOtherController = TextEditingController();
  final _postingStateController = TextEditingController(text: 'Uttar Pradesh');
  final _postingStateOtherController = TextEditingController();
  final _officialNameController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _batchYearOtherController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _callingNumberController = TextEditingController();
  final _postingPlaceLocationController = TextEditingController();
  final _homeDistrictController = TextEditingController();
  final _homeDistrictOtherController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingDistrictOtherController = TextEditingController();
  final _postingLocationController = TextEditingController();
  final _postingLocationOtherController = TextEditingController();
  final _homeVillageMohallaController = TextEditingController();
  final _homeGaliNoController = TextEditingController();
  final _homePostOfficeController = TextEditingController();
  final _homePoliceStationController = TextEditingController();
  final _homePoliceStationOtherController = TextEditingController();
  final _homeTehsilController = TextEditingController();
  final _homeTehsilOtherController = TextEditingController();
  final _homeStateCountyController = TextEditingController();
  XFile? _selfie;
  XFile? _idCardPhoto;
  Member? _referenceMember;
  int _currentStep = 0;
  bool _submitting = false;
  final LocationSuggestionService _locationSuggestions = LocationSuggestionService();
  List<String> _allStateOptions = <String>[];
  List<String> _allDistrictOptions = <String>[];
  List<String> _homeDistrictOptions = <String>[];
  List<String> _postingDistrictOptions = <String>[];
  List<String> _allHomeStationOptions = <String>[];
  List<String> _allPostingStationOptions = <String>[];
  List<String> _allPostingPlaceOptions = <String>[];
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final EmailOtpService _emailOtpService = EmailOtpService();
  bool _biometricSupported = false;
  bool _biometricVerified = false;
  bool _emailVerified = false;
  bool _emailOtpSent = false;
  bool _sendingEmailOtp = false;
  bool _verifyingEmailOtp = false;
  bool _referenceEmailVerified = false;
  bool _referenceEmailOtpSent = false;
  bool _sendingReferenceEmailOtp = false;
  bool _verifyingReferenceEmailOtp = false;
  bool _showOtpSendButton = false;
  bool _checkingBiometric = false;
  bool _capturingPostingLocation = false;
  bool _uploadPostingGpsLater = false;
  bool _officialNameEditedByUser = false;
  bool _acceptedTerms = false;
  Timer? _otpResendTimer;
  int _otpResendSeconds = 0;
  Timer? _referenceOtpResendTimer;
  int _referenceOtpResendSeconds = 0;
  final Map<String, GlobalKey> _fieldKeys = <String, GlobalKey>{};
  final Set<String> _invalidFieldIds = <String>{};
  final Map<String, String> _fieldErrors = <String, String>{};

  static const List<String> _subDepartments = <String>[
    'Civil Police',
    'P.A.C',
    'Fire Service',
    'Jail Warden',
    'Armed Police',
    'UPSSF',
    'GRP',
    'Dial 112',
    'LIU',
    'Radio Department',
    'Others',
  ];

  static const List<String> _rankOptions = <String>[
    'Constable',
    'Head Constable',
    'Computer Operator',
    'ASI',
    'SI',
    'Inspector',
    'Other',
  ];

  static const List<String> _genderOptions = <String>[
    'Male',
    'Female',
    'Other',
  ];

  static const List<String> _maritalStatusOptions = <String>[
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Other',
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
    'Other',
  ];

  static const List<String> _postingPlaceOptions = <String>[
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
    'Writt Cell',
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
    'Monitoring Cell',
    'Media Cell',
    'Trinetr Cell',
    'Crime Branch',
    'Police Canteen',
    'Gas Agency',
    'District Field Unit',
    'Anti Power Theft',
    'Samman Cell',
    'Other',
  ];

  static final RegExp _namePattern = RegExp(r"^[A-Za-z][A-Za-z .'-]{1,59}$");
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _yearPattern = RegExp(r'^[0-9]{4}$');

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    unawaited(_primeFormOptions());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _emailOtpController.dispose();
    _mpinController.dispose();
    _referenceController.dispose();
    _referenceEmailController.dispose();
    _referenceEmailOtpController.dispose();
    _departmentController.dispose();
    _departmentOtherController.dispose();
    _postRankController.dispose();
    _customRankController.dispose();
    _genderController.dispose();
    _genderOtherController.dispose();
    _maritalStatusController.dispose();
    _maritalStatusOtherController.dispose();
    _postingCategoryController.dispose();
    _postingCategoryOtherController.dispose();
    _postingWorkAsController.dispose();
    _postingWorkAsOtherController.dispose();
    _homeStateController.dispose();
    _homeStateOtherController.dispose();
    _postingStateController.dispose();
    _postingStateOtherController.dispose();
    _officialNameController.dispose();
    _batchYearController.dispose();
    _batchYearOtherController.dispose();
    _whatsappController.dispose();
    _callingNumberController.dispose();
    _postingPlaceLocationController.dispose();
    _homeDistrictController.dispose();
    _homeDistrictOtherController.dispose();
    _postingDistrictController.dispose();
    _postingDistrictOtherController.dispose();
    _postingLocationController.dispose();
    _postingLocationOtherController.dispose();
    _homeVillageMohallaController.dispose();
    _homeGaliNoController.dispose();
    _homePostOfficeController.dispose();
    _homePoliceStationController.dispose();
    _homePoliceStationOtherController.dispose();
    _homeTehsilController.dispose();
    _homeTehsilOtherController.dispose();
    _homeStateCountyController.dispose();
    _otpResendTimer?.cancel();
    _referenceOtpResendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF3EEE2), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _buildScreenHeader(keyboardOpen),
              Padding(
                padding: EdgeInsets.fromLTRB(20, keyboardOpen ? 8 : 10, 20, 0),
                child: _buildStepStrip(),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _buildIdentityStep(),
                    _buildEmailVerificationStep(),
                    _buildReferralStep(),
                    _buildPostingDetailsStep(),
                    _buildHomeDetailsStep(),
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

  Widget _buildScreenHeader(bool keyboardOpen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: keyboardOpen ? 0 : 66,
      margin: EdgeInsets.fromLTRB(20, keyboardOpen ? 0 : 8, 20, 0),
      child: keyboardOpen
          ? const SizedBox.shrink()
          : Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Member Registration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepStrip() {
    final progress = (_currentStep + 1) / _steps.length;
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE0DDD5),
            valueColor: AlwaysStoppedAnimation<Color>(_ink),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5A6B74),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepPage(
      title: 'Basic detail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE2CB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.badge_outlined, color: _ink, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Identity profile',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  _nameController,
                  'Full Name',
                  isRequired: true,
                  onChanged: _syncOfficialNameFromIdentity,
                ),
                _buildTextField(
                  _mobileController,
                  'Mobile No.',
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  digitsOnly: true,
                ),
                _buildTextField(
                  _mpinController,
                  'Security M-PIN',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  digitsOnly: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Biometric verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFingerprintOption(),
                const SizedBox(height: 8),
                Text(
                  _biometricSupported
                      ? 'Use device biometrics to approve this registration on supported devices.'
                      : 'Biometric verification is unavailable on this device.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5B6470)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationStep() {
    return _buildStepPage(
      title: 'Verify self email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Self email OTP verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  _emailController,
                  'Self Email Address',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailVerified || _emailOtpSent || _emailOtpController.text.isNotEmpty) {
                      setState(() {
                        _emailVerified = false;
                        _emailOtpSent = false;
                        _showOtpSendButton = false;
                        _emailOtpController.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                if (!_emailVerified)
                  FilledButton.icon(
                    onPressed: _sendingEmailOtp ? null : _sendRegistrationEmailOtp,
                    icon: _sendingEmailOtp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(_sendingEmailOtp
                        ? 'Sending OTP...'
                        : (_emailOtpSent && _otpResendSeconds > 0
                            ? 'Resend in $_otpResendSeconds s'
                            : (_emailOtpSent ? 'Resend OTP' : 'Send OTP'))),
                  ),
                if (_emailOtpSent) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_verifyingEmailOtp && !_emailVerified,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.trim().length == 6 && !_verifyingEmailOtp) {
                        unawaited(_verifyRegistrationEmail());
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email OTP',
                      hintText: '000000',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStep() {
    return _buildStepPage(
      title: 'Verify referral email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Referring member mobile no.',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  _referenceController,
                  'Referring Mobile No.',
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  digitsOnly: true,
                  onChanged: (_) => _syncReferenceMember(),
                ),
                const SizedBox(height: 10),
                if (_referenceMember != null) _buildReferenceMemberCard(_referenceMember!),
                const SizedBox(height: 12),
                const Text(
                  'Referral email OTP',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 12),
                if (!_referenceEmailVerified)
                  FilledButton.icon(
                    onPressed: _sendingReferenceEmailOtp ? null : _sendReferenceEmailOtp,
                    icon: _sendingReferenceEmailOtp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(_sendingReferenceEmailOtp
                        ? 'Sending OTP...'
                        : (_referenceEmailOtpSent && _referenceOtpResendSeconds > 0
                            ? 'Resend in $_referenceOtpResendSeconds s'
                            : (_referenceEmailOtpSent ? 'Resend OTP' : 'Send OTP'))),
                  ),
                if (_referenceEmailOtpSent) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referenceEmailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_verifyingReferenceEmailOtp && !_referenceEmailVerified,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.trim().length == 6 && !_verifyingReferenceEmailOtp) {
                        unawaited(_verifyReferenceEmailOtp());
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Referral OTP',
                      hintText: '000000',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDetailsStep() {
    return _buildStepPage(
      title: 'Home details',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: 'Home details',
            initiallyExpanded: true,
            children: <Widget>[
              _buildSelectionField(
                _homeStateController,
                'Home State',
                isRequired: true,
                hint: 'Tap to choose state',
                onTap: () => _pickFromList(
                  title: 'Select Home State',
                  options: _allStateOptions,
                  controller: _homeStateController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    setState(() {
                      _homeDistrictController.clear();
                      _homePoliceStationController.clear();
                    });
                    unawaited(_loadHomeDistrictOptions());
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              _buildSelectionField(
                _homeDistrictController,
                'Home District',
                isRequired: true,
                hint: 'Tap to choose from district list',
                onTap: () => _pickFromList(
                  title: 'Select Home District',
                  options: _homeDistrictOptions,
                  controller: _homeDistrictController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    setState(() {
                      _homePoliceStationController.clear();
                    });
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              _buildTextField(_homeTehsilController, 'Home Tehsil', isRequired: true),
              _buildSelectionField(
                _homePoliceStationController,
                'Home Police Station',
                isRequired: true,
                hint: 'Tap to choose station',
                onTap: () => _pickFromList(
                  title: 'Select Home Police Station',
                  options: _allHomeStationOptions,
                  controller: _homePoliceStationController,
                  allowCustomValue: true,
                ),
              ),
              _buildTextField(_homeVillageMohallaController, 'Village / Mohalla', isRequired: true),
              _buildTextField(_homeGaliNoController, 'Gali No.', isRequired: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostingDetailsStep() {
    return _buildStepPage(
      title: 'Posting details',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: 'Posting location details',
            initiallyExpanded: true,
            children: <Widget>[
              _buildSelectionField(
                _postingStateController,
                'Posting State',
                isRequired: true,
                hint: 'Tap to choose state',
                onTap: () => _pickFromList(
                  title: 'Select Posting State',
                  options: _allStateOptions,
                  controller: _postingStateController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    setState(() {
                      _postingDistrictController.clear();
                      _postingLocationController.clear();
                      _postingPlaceLocationController.clear();
                    });
                    unawaited(_loadPostingDistrictOptions());
                    unawaited(_loadPostingStationOptions());
                    unawaited(_loadPostingPlaceOptions());
                  },
                ),
              ),
              _buildSelectionField(
                _postingDistrictController,
                'Posting District',
                isRequired: true,
                hint: 'Tap to choose district',
                onTap: () => _pickFromList(
                  title: 'Select Posting District',
                  options: _postingDistrictOptions,
                  controller: _postingDistrictController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    setState(() {
                      _postingLocationController.clear();
                    });
                    unawaited(_loadPostingStationOptions());
                  },
                ),
              ),
              _buildDropdownField(
                _departmentController,
                'Sub Department',
                _subDepartments,
                isRequired: true,
              ),
              _buildDropdownField(
                _postingCategoryController,
                'Posting Category',
                _postingCategories,
                isRequired: true,
                onChanged: (value) {
                  setState(() {
                    _postingLocationController.clear();
                    _postingLocationOtherController.clear();
                  });
                  if (value == 'Police Station') {
                    unawaited(_loadPostingStationOptions());
                  } else {
                    unawaited(_loadPostingPlaceOptions());
                  }
                },
              ),
              _buildPostingPlaceField(),
              _buildTextField(
                _postingPlaceLocationController,
                'Posting GPS Location',
                isRequired: !_uploadPostingGpsLater,
                readOnly: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _uploadPostingGpsLater,
                onChanged: (value) {
                  final uploadLater = value ?? false;
                  setState(() {
                    _uploadPostingGpsLater = uploadLater;
                  });
                  if (uploadLater) {
                    _clearFieldError('Posting GPS Location');
                  }
                },
                title: const Text('Upload posting GPS later'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _capturingPostingLocation ? null : _capturePostingLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(
                    _capturingPostingLocation
                        ? 'Capturing location...'
                        : 'Use current GPS as posting location',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildChunkCard(
            title: 'Service profile details',
            initiallyExpanded: true,
            children: <Widget>[
              const SizedBox(height: 10),
              _buildTextField(
                _officialNameController,
                'Official Name',
                isRequired: true,
                onChanged: _markOfficialNameEdited,
              ),
              _buildDropdownField(_postRankController, 'Rank', _rankOptions, isRequired: true),
              if (_postRankController.text == 'Other')
                _buildTextField(_customRankController, 'Enter rank name', uppercase: true),
              _buildDropdownField(_batchYearController, 'Batch Year', _batchYears(), isRequired: true),
              _buildDropdownField(_genderController, 'Gender', _genderOptions, isRequired: true),
              _buildDropdownField(
                _maritalStatusController,
                'Marital Status',
                _maritalStatusOptions,
                isRequired: true,
              ),
              _buildDropdownField(
                _postingWorkAsController,
                'Posting Work As',
                _postingWorkOptions,
                isRequired: true,
              ),
              _buildTextField(
                _whatsappController,
                'Whatsapp Number',
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
              _buildTextField(
                _callingNumberController,
                'Calling Contact No.',
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostingPlaceField() {
    final isPoliceStation = _postingCategoryController.text.trim() == 'Police Station';
    final options = isPoliceStation ? _allPostingStationOptions : _allPostingPlaceOptions;
    final label = isPoliceStation ? 'Posting Police Station' : 'Posting Place Name';
    final hint = isPoliceStation ? 'Tap to choose police station' : 'Tap to choose place name';
    final title = isPoliceStation ? 'Select Posting Police Station' : 'Select Posting Place Name';

    return _buildSelectionField(
      _postingLocationController,
      label,
      fieldId: 'Posting Place Name',
      isRequired: true,
      hint: hint,
      onTap: () => _pickFromList(
        title: title,
        options: options,
        controller: _postingLocationController,
        allowCustomValue: true,
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return _buildStepPage(
      title: 'Photos',
      child: Column(
        children: <Widget>[
          _buildUploadTile(
            title: 'Selfie photo',
            icon: Icons.camera_alt_outlined,
            onTap: _pickSelfie,
          ),
          if (_selfie != null) _buildImagePreview(_selfie!),
          const SizedBox(height: 12),
          _buildUploadTile(
            title: 'ID proof photo',
            icon: Icons.badge_outlined,
            onTap: _pickIdCardPhoto,
          ),
          if (_idCardPhoto != null) _buildImagePreview(_idCardPhoto!),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'A selfie is required so the admin can confirm the profile photo before approval.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepPage(
      title: 'Review and submit',
      child: Column(
        children: <Widget>[
          _buildSummaryRow('Full name', _nameController.text.trim()),
          _buildSummaryRow('Self email', _emailController.text.trim()),
          _buildSummaryRow('Mobile', _mobileController.text.trim()),
          _buildSummaryRow('M-PIN', '******'),
          _buildSummaryRow('Biometric', _biometricVerified ? 'Verified' : 'Not verified'),
          _buildSummaryRow('Referring mobile', _referenceController.text.trim()),
          _buildSummaryRow('Referring email', _referenceMember?.email?.trim() ?? '-'),
          _buildSummaryRow('Ref email OTP', _referenceEmailVerified ? 'Verified' : 'Pending'),
          _buildSummaryRow('Posting state', _effectiveValue(_postingStateController, _postingStateOtherController)),
          _buildSummaryRow('Posting district', _effectiveValue(_postingDistrictController, _postingDistrictOtherController)),
          _buildSummaryRow('Posting category', _effectiveValue(_postingCategoryController, _postingCategoryOtherController)),
          _buildSummaryRow('Posting place', _effectiveValue(_postingLocationController, _postingLocationOtherController)),
          _buildSummaryRow('Posting GPS', _postingPlaceLocationController.text.trim().isEmpty ? (_uploadPostingGpsLater ? 'Will upload later' : 'Not captured') : 'Captured'),
          _buildSummaryRow('Sub department', _effectiveValue(_departmentController, _departmentOtherController)),
          _buildSummaryRow('Official name', _officialNameController.text.trim()),
          _buildSummaryRow('Rank', _effectiveValue(_postRankController, _customRankController)),
          _buildSummaryRow('Batch year', _effectiveValue(_batchYearController, _batchYearOtherController)),
          _buildSummaryRow('Gender', _effectiveValue(_genderController, _genderOtherController)),
          _buildSummaryRow('Marital status', _effectiveValue(_maritalStatusController, _maritalStatusOtherController)),
          _buildSummaryRow('Work type', _effectiveValue(_postingWorkAsController, _postingWorkAsOtherController)),
          _buildSummaryRow('WhatsApp', _whatsappController.text.trim()),
          _buildSummaryRow('Calling', _callingNumberController.text.trim()),
          _buildSummaryRow('Home state', _effectiveValue(_homeStateController, _homeStateOtherController)),
          _buildSummaryRow('Home district', _effectiveValue(_homeDistrictController, _homeDistrictOtherController)),
          _buildSummaryRow('Home police station', _effectiveValue(_homePoliceStationController, _homePoliceStationOtherController)),
          _buildSummaryRow('Home village', _homeVillageMohallaController.text.trim()),
          _buildSummaryRow('Post office', _homePostOfficeController.text.trim()),
          _buildSummaryRow('Gali no.', _homeGaliNoController.text.trim()),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBD8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Registration remains pending until admin approval.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsPrivacyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Read terms and privacy'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  title: const Text('I agree to the terms and privacy policy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage({
    required String title,
    required Widget child,
  }) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 110),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 0.2,
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: _border,
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
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
            child:
                Text(label, style: const TextStyle(color: Color(0xFF5A6B74), fontWeight: FontWeight.w600)),
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
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom + 8 : 16.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: <Widget>[
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _submitting ? null : _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
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

  Widget _buildFingerprintOption() {
    if (!_biometricSupported) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.fingerprint_outlined, color: Color(0xFF5A6B74)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fingerprint option is not available on this device.',
                style: TextStyle(color: Color(0xFF5A6B74)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _biometricVerified ? const Color(0xFFE8F5ED) : const Color(0xFFF4EBD8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _biometricVerified ? const Color(0xFF9CCDB0) : const Color(0xFFE0D0AE),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _biometricVerified ? Icons.verified_outlined : Icons.fingerprint,
            color: _ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _biometricVerified
                  ? 'Fingerprint verified. You can use biometric login after registration.'
                  : 'Optional: verify fingerprint while setting your M-PIN.',
              style: const TextStyle(color: _ink),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _checkingBiometric ? null : _verifyFingerprint,
            child: Text(_checkingBiometric ? 'Checking...' : (_biometricVerified ? 'Re-check' : 'Verify')),
          ),
        ],
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    String? fieldId,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool digitsOnly = false,
    bool uppercase = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    final id = fieldId ?? label;
    return TextFormField(
      key: _fieldKey(id),
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      maxLength: maxLength,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : (uppercase
            ? <TextInputFormatter>[_UpperCaseTextFormatter()]
            : null),
      onChanged: (value) {
        if (value.trim().isNotEmpty) {
          _clearFieldError(id);
        }
        onChanged?.call(value);
      },
      onTap: onTap,
      decoration: _fieldDecoration(
        label,
        isRequired: isRequired,
        errorText: _fieldErrors[id],
      ),
    );
  }

  Widget _buildChunkCard({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        children: children,
      ),
    );
  }

  Widget _buildSelectionField(
    TextEditingController controller,
    String label, {
    String? fieldId,
    bool isRequired = false,
    required Future<void> Function() onTap,
    String? hint,
  }) {
    final id = fieldId ?? label;
    return GestureDetector(
      key: _fieldKey(id),
      onTap: () async {
        await onTap();
        if (controller.text.trim().isNotEmpty) {
          _clearFieldError(id);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: _fieldDecoration(label, isRequired: isRequired).copyWith(
            hintText: hint,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            errorText: _fieldErrors[id],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    List<String> options,
    {String? fieldId, bool isRequired = false, ValueChanged<String>? onChanged,}
  ) {
    final id = fieldId ?? label;
    final current = controller.text.trim();
    final selected = options.contains(current) ? current : null;
    return Padding(
      key: _fieldKey(id),
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        items: options
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value ?? '';
            if (label == 'Rank' && controller.text != 'Other') {
              _customRankController.clear();
            }
            _clearFieldError(id);
          });
          onChanged?.call(value ?? '');
        },
        decoration: _fieldDecoration(
          label,
          isRequired: isRequired,
          errorText: _fieldErrors[id],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    bool isRequired = false,
    String? errorText,
  }) {
    final labelText = isRequired ? '$label *' : label;
    return InputDecoration(
      labelText: labelText,
      floatingLabelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      errorText: errorText,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      counterText: '',
    );
  }

  GlobalKey _fieldKey(String fieldId) {
    return _fieldKeys.putIfAbsent(fieldId, () => GlobalKey());
  }

  void _clearFieldError(String fieldId) {
    if (!_invalidFieldIds.contains(fieldId)) {
      return;
    }
    setState(() {
      _invalidFieldIds.remove(fieldId);
      _fieldErrors.remove(fieldId);
    });
  }

  Future<void> _markInvalidFields(
    List<String> fieldIds,
    String firstMessage,
    {bool showMessage = true, bool scroll = true}
  ) async {
    setState(() {
      _invalidFieldIds
        ..clear()
        ..addAll(fieldIds);
      _fieldErrors
        ..clear()
        ..addEntries(fieldIds.map((id) => MapEntry<String, String>(id, firstMessage)));
    });
    if (showMessage) {
      _showMessage(firstMessage);
    }
    if (fieldIds.isEmpty || !scroll) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    final context = _fieldKeys[fieldIds.first]?.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.18,
      );
    }
  }

  void _syncOfficialNameFromIdentity(String value) {
    final fullName = value.trim();
    if (_officialNameEditedByUser && _officialNameController.text.trim().isNotEmpty) {
      return;
    }
    _officialNameController.value = TextEditingValue(
      text: fullName,
      selection: TextSelection.collapsed(offset: fullName.length),
    );
  }

  void _markOfficialNameEdited(String value) {
    _officialNameEditedByUser = value.trim().isNotEmpty;
  }

  String _selectedValue(
    TextEditingController controller,
    TextEditingController otherController,
  ) {
    final selected = controller.text.trim();
    if (selected == 'Other') {
      return otherController.text.trim();
    }
    return selected;
  }

  String _effectiveValue(
    TextEditingController controller,
    TextEditingController otherController,
  ) {
    final value = _selectedValue(controller, otherController).trim();
    if (controller.text.trim() == 'Other') {
      return value.toUpperCase();
    }
    return value;
  }

  void _syncReferenceMember() {
    final mobile = _referenceController.text.trim();

    final byMobile = widget.repository.findByMobile(mobile);

    setState(() {
      if (mobile.isEmpty) {
        _referenceMember = null;
      } else {
        _referenceMember = byMobile;
      }

      if (_referenceEmailVerified) {
        _referenceEmailVerified = false;
        _referenceEmailOtpSent = false;
        _referenceEmailOtpController.clear();
        _referenceOtpResendTimer?.cancel();
        _referenceOtpResendSeconds = 0;
      }
    });

    if (_referenceMember != null &&
        !_referenceEmailVerified &&
        !_sendingReferenceEmailOtp &&
        !_referenceEmailOtpSent) {
      unawaited(_sendReferenceEmailOtp());
    }
  }

  Widget _buildReferenceMemberCard(Member member) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6ECD5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  '${member.email ?? 'No email on file'} • ${member.role}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5B6470)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReferenceEmailOtp() async {
    final member = _referenceMember;
    final email = member?.email?.trim() ?? '';
    if (member == null) {
      _showMessage('Enter a valid referral mobile number first.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('No email is attached to this referral mobile number.');
      return;
    }

    setState(() {
      _sendingReferenceEmailOtp = true;
    });

    try {
      final dispatch = await _emailOtpService.sendVerificationOtp(
        email,
        purpose: EmailOtpPurpose.registration,
        memberName: member.name,
      );

      if (!mounted) {
        return;
      }

      if (!dispatch.success) {
        setState(() {
          _sendingReferenceEmailOtp = false;
        });
        _showMessage(dispatch.error ?? 'Unable to send referral OTP.');
        return;
      }

      _referenceOtpResendTimer?.cancel();
      setState(() {
        _sendingReferenceEmailOtp = false;
        _referenceEmailOtpSent = true;
        _referenceOtpResendSeconds = 600;
      });

      _referenceOtpResendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _referenceOtpResendTimer?.cancel();
          return;
        }
        setState(() {
          if (_referenceOtpResendSeconds > 0) {
            _referenceOtpResendSeconds--;
          } else {
            _referenceOtpResendTimer?.cancel();
          }
        });
      });

      _showMessage('OTP sent to referring member email.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendingReferenceEmailOtp = false;
      });
      _showMessage('Unable to send referral OTP right now.');
    }
  }

  Future<bool> _verifyReferenceEmailOtp() async {
    if (_referenceEmailVerified) {
      return true;
    }

    final email = _referenceMember?.email?.trim() ?? '';
    final otp = _referenceEmailOtpController.text.trim();
    if (email.isEmpty || otp.length != 6) {
      return false;
    }

    setState(() {
      _verifyingReferenceEmailOtp = true;
    });

    final verified = await _emailOtpService.verifyOtp(email: email, otp: otp);

    if (!mounted) {
      return false;
    }

    setState(() {
      _verifyingReferenceEmailOtp = false;
    });

    if (!verified) {
      _showMessage('Invalid or expired referral OTP.');
      return false;
    }

    setState(() {
      _referenceEmailVerified = true;
    });
    return true;
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 65);
    if (file != null) {
      setState(() {
        _selfie = file;
      });
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      final available = await _localAuthentication.getAvailableBiometrics();
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = (canCheck || isSupported) && available.isNotEmpty;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = false;
      });
    }
  }

  Future<void> _verifyFingerprint() async {
    if (!_biometricSupported) {
      _showMessage('Fingerprint is not available on this device.');
      return;
    }

    setState(() {
      _checkingBiometric = true;
    });

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Verify fingerprint for quick login after registration',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricVerified = authenticated;
      });
      _showMessage(
        authenticated
            ? 'Fingerprint verified successfully.'
            : 'Fingerprint verification was cancelled.',
      );
    } on PlatformException {
      if (!mounted) {
        return;
      }
      _showMessage('Fingerprint verification is unavailable on this device.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to verify fingerprint right now.');
    } finally {
      if (mounted) {
        setState(() {
          _checkingBiometric = false;
        });
      }
    }
  }

  Future<void> _pickIdCardPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() {
        _idCardPhoto = file;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentStep == 0) {
      if (!await _validateIdentityStep()) {
        return;
      }
      await _goToStep(1);
      return;
    }

    if (_currentStep == 1) {
      if (!await _validateSelfEmailStep()) {
        return;
      }
      await _goToStep(2);
      return;
    }

    if (_currentStep == 2) {
      if (!await _validateReferralStep()) {
        return;
      }
      await _goToStep(3);
      return;
    }

    if (_currentStep == 3) {
      if (!await _validatePostingStep()) {
        return;
      }
      await _goToStep(4);
      return;
    }

    if (_currentStep == 4) {
      if (!await _validateHomeStep()) {
        return;
      }
      await _goToStep(5);
      return;
    }

    if (_currentStep == 5) {
      if (!await _validateDocumentsStep()) {
        return;
      }
      await _goToStep(6);
      return;
    }

    if (_currentStep == 6) {
      if (!await _validateReviewStep()) {
        return;
      }
      await _submit();
    }
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

  Future<bool> _validateIdentityStep({bool showFeedback = true}) async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final mpin = _mpinController.text.trim();
    if (name.isEmpty || mobile.isEmpty || mpin.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (name.isEmpty) 'Full Name',
          if (mobile.isEmpty) 'Mobile No.',
          if (mpin.isEmpty) 'Security M-PIN',
        ],
        'Complete your personal information first.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!_namePattern.hasMatch(name)) {
      await _markInvalidFields(
        <String>['Full Name'],
        'Enter a valid full name (letters and spaces only).',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!_mobilePattern.hasMatch(mobile)) {
      await _markInvalidFields(
        <String>['Mobile No.'],
        'Mobile number must be 10 digits.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (mpin.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(mpin)) {
      await _markInvalidFields(
        <String>['Security M-PIN'],
        'M-PIN must be exactly 6 digits.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (widget.repository.findByMobile(mobile) != null) {
      await _markInvalidFields(
        <String>['Mobile No.'],
        'Mobile number already registered.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (_biometricSupported && !_biometricVerified) {
      _showMessage('Please complete biometric verification on this device.');
      return false;
    }
    return true;
  }

  Future<bool> _validateSelfEmailStep({bool showFeedback = true}) async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (email.isEmpty) {
      await _markInvalidFields(
        <String>['Self Email Address'],
        'Enter your self email address.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!emailRegex.hasMatch(email)) {
      await _markInvalidFields(
        <String>['Self Email Address'],
        'Enter a valid email address.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (widget.repository.findByEmail(email) != null) {
      await _markInvalidFields(
        <String>['Self Email Address'],
        'Email already registered.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!_emailVerified) {
      _showMessage('Verify your self email OTP before continuing.');
      return false;
    }
    return true;
  }

  Future<bool> _ensureIdentityNotDuplicateInCloud() async {
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    final byMobile = await widget.repository.fetchByMobileFromCloud(mobile);
    if (byMobile != null) {
      _showMessage('Mobile number already registered in system.');
      return false;
    }

    final byEmail = await widget.repository.fetchByEmailFromCloud(email);
    if (byEmail != null) {
      _showMessage('Email already registered in system.');
      return false;
    }
    return true;
  }

  Future<bool> _validateReferralStep({bool showFeedback = true}) async {
    final mobile = _referenceController.text.trim();
    final errors = <String>[];
    if (mobile.isEmpty) {
      errors.add('Referring Mobile No.');
    }
    if (_referenceMember == null) {
      errors.add('Referring member');
    }
    if (!_referenceEmailVerified) {
      errors.add('Referral OTP');
    }

    if (errors.isNotEmpty) {
      await _markInvalidFields(
        errors,
        'Complete and verify the referral details first.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    final memberEmail = _referenceMember!.email?.trim().toLowerCase() ?? '';
    if (memberEmail.isEmpty) {
      await _markInvalidFields(
        <String>['Referring member'],
        'No email is attached to this referral mobile number.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (_referenceMember!.mobileNumber.trim() != mobile) {
      await _markInvalidFields(
        <String>['Referring Mobile No.'],
        'Referral mobile does not match the linked member.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _verifyRegistrationEmail() async {
    if (_emailVerified) {
      return true;
    }

    if (!_emailOtpSent) {
      await _markInvalidFields(<String>['Enter OTP'], 'Please send OTP first.');
      return false;
    }

    final enteredOtp = _emailOtpController.text.trim();
    if (enteredOtp.length != 6) {
      await _markInvalidFields(<String>['Enter OTP'], 'Enter valid 6 digit OTP.');
      return false;
    }

    final email = _emailController.text.trim();
    setState(() {
      _verifyingEmailOtp = true;
    });

    final verified = await _emailOtpService.verifyOtp(
      email: email,
      otp: enteredOtp,
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      _verifyingEmailOtp = false;
    });

    if (!verified) {
      await _markInvalidFields(<String>['Enter OTP'], 'Invalid or expired email OTP.');
      return false;
    }

    setState(() {
      _emailVerified = true;
    });
    return true;
  }

  Future<void> _sendRegistrationEmailOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    setState(() {
      _sendingEmailOtp = true;
    });

    try {
      final dispatch = await _emailOtpService.sendVerificationOtp(
        email,
        purpose: EmailOtpPurpose.registration,
        memberName: _nameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (!dispatch.success) {
        setState(() {
          _sendingEmailOtp = false;
          _showOtpSendButton = true;
        });
        _showMessage(dispatch.error ?? 'Unable to send email OTP.');
        return;
      }

      // Start resend countdown timer
      _otpResendTimer?.cancel();
      setState(() {
        _sendingEmailOtp = false;
        _emailOtpSent = true;
        _otpResendSeconds = 300;
        _showOtpSendButton = false;
      });

      _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _otpResendTimer?.cancel();
          return;
        }
        setState(() {
          if (_otpResendSeconds > 0) {
            _otpResendSeconds--;
          } else {
            _otpResendTimer?.cancel();
          }
        });
      });

      _showMessage('OTP sent to $email');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendingEmailOtp = false;
        _showOtpSendButton = true;
      });
      _showMessage('Unable to send email OTP right now. Please try again.');
    }
  }

  Future<bool> _validateHomeStep({bool showFeedback = true}) async {
    final homeState = _selectedValue(_homeStateController, _homeStateOtherController);
    final homeDistrict = _effectiveValue(_homeDistrictController, _homeDistrictOtherController);
    final homeVillageMohalla = _homeVillageMohallaController.text.trim();
    final homeGaliNo = _homeGaliNoController.text.trim();
    final homePoliceStation = _effectiveValue(_homePoliceStationController, _homePoliceStationOtherController);
    final homeTehsil = _homeTehsilController.text.trim();
    final homePostOffice = _homePostOfficeController.text.trim();

    if (homeState.isEmpty ||
        homeDistrict.isEmpty ||
        homeVillageMohalla.isEmpty ||
        homeGaliNo.isEmpty ||
        homePoliceStation.isEmpty ||
        homeTehsil.isEmpty ||
        homePostOffice.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (homeState.isEmpty) 'Home State',
          if (homeDistrict.isEmpty) 'Home District',
          if (homeVillageMohalla.isEmpty) 'Village / Mohalla',
          if (homeGaliNo.isEmpty) 'Gali No.',
          if (homePoliceStation.isEmpty) 'Home Police Station',
          if (homeTehsil.isEmpty) 'Home Tehsil',
          if (homePostOffice.isEmpty) 'Post Office',
        ],
        'Complete all home district details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (homeState.length < 2 || homeDistrict.length < 2) {
      await _markInvalidFields(
        <String>[if (homeState.length < 2) 'Home State', if (homeDistrict.length < 2) 'Home District'],
        'Enter a valid home state and district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _validatePostingStep({bool showFeedback = true}) async {
    final postingState = _selectedValue(_postingStateController, _postingStateOtherController);
    final postingDistrict = _effectiveValue(_postingDistrictController, _postingDistrictOtherController);
    final postingCategory = _effectiveValue(_postingCategoryController, _postingCategoryOtherController);
    final postingPlace = _effectiveValue(_postingLocationController, _postingLocationOtherController);
    final postingGps = _postingPlaceLocationController.text.trim();
    final department = _effectiveValue(_departmentController, _departmentOtherController);
    final rank = _effectiveValue(_postRankController, _customRankController);
    final batchYear = _effectiveValue(_batchYearController, _batchYearOtherController);
    final gender = _effectiveValue(_genderController, _genderOtherController);
    final maritalStatus = _effectiveValue(_maritalStatusController, _maritalStatusOtherController);
    final postingWorkAs = _effectiveValue(_postingWorkAsController, _postingWorkAsOtherController);
    final officialName = _officialNameController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final callingContact = _callingNumberController.text.trim();

    if (postingState.isEmpty ||
        postingDistrict.isEmpty ||
        postingCategory.isEmpty ||
        postingPlace.isEmpty ||
        department.isEmpty ||
        rank.isEmpty ||
        batchYear.isEmpty ||
        gender.isEmpty ||
        maritalStatus.isEmpty ||
        postingWorkAs.isEmpty ||
        officialName.isEmpty ||
        whatsapp.isEmpty ||
        callingContact.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (postingState.isEmpty) 'Posting State',
          if (postingDistrict.isEmpty) 'Posting District',
          if (postingCategory.isEmpty) 'Posting Category',
          if (postingPlace.isEmpty) 'Posting Place Name',
          if (department.isEmpty) 'Sub Department',
          if (rank.isEmpty) 'Rank',
          if (batchYear.isEmpty) 'Batch Year',
          if (gender.isEmpty) 'Gender',
          if (maritalStatus.isEmpty) 'Marital Status',
          if (postingWorkAs.isEmpty) 'Posting Work As',
          if (officialName.isEmpty) 'Official Name',
          if (whatsapp.isEmpty) 'WhatsApp No.',
          if (callingContact.isEmpty) 'Calling No.',
        ],
        'Complete all posting details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingState.length < 2 || postingDistrict.length < 2) {
      await _markInvalidFields(
        <String>[if (postingState.length < 2) 'Posting State', if (postingDistrict.length < 2) 'Posting District'],
        'Enter a valid posting state and district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (_postingCategoryController.text.trim() == 'Police Station') {
      if (postingPlace.length < 3) {
        await _markInvalidFields(
          <String>['Posting Police Station'],
          'Select or enter a valid police station.',
          showMessage: showFeedback,
          scroll: showFeedback,
        );
        return false;
      }
    } else if (postingPlace.length < 3) {
      await _markInvalidFields(
        <String>['Posting Place Name'],
        'Select or enter a valid posting place name.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (department.length < 2 || rank.length < 2 || postingWorkAs.length < 2) {
      await _markInvalidFields(
        <String>[
          if (department.length < 2) 'Sub Department',
          if (rank.length < 2) 'Rank',
          if (postingWorkAs.length < 2) 'Posting Work As',
        ],
        'Select valid posting service details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    final currentYear = DateTime.now().year;
    final batch = int.tryParse(batchYear);
    if (!_yearPattern.hasMatch(batchYear) || batch == null || batch < 1970 || batch > currentYear) {
      await _markInvalidFields(
        <String>['Batch Year'],
        'Enter a valid batch year.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_namePattern.hasMatch(officialName)) {
      await _markInvalidFields(
        <String>['Official Name'],
        'Enter a valid official name.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_mobilePattern.hasMatch(whatsapp) || !_mobilePattern.hasMatch(callingContact)) {
      await _markInvalidFields(
        <String>[
          if (!_mobilePattern.hasMatch(whatsapp)) 'WhatsApp No.',
          if (!_mobilePattern.hasMatch(callingContact)) 'Calling No.',
        ],
        'Enter valid WhatsApp and calling numbers.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingGps.isEmpty && !_uploadPostingGpsLater) {
      await _markInvalidFields(
        <String>['Posting GPS Location'],
        'Please fetch posting GPS location or choose Upload posting GPS later.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _validateServiceStep({bool showFeedback = true}) async {

    final department = _departmentController.text.trim();
    final postRank = _postRankController.text.trim();
    final customRank = _customRankController.text.trim();
    final officialName = _officialNameController.text.trim();
    final batchYear = _batchYearController.text.trim();
    final gender = _genderController.text.trim();
    final maritalStatus = _maritalStatusController.text.trim();
    final postingCategory = _postingCategoryController.text.trim();
    final postingWorkAs = _postingWorkAsController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final callingContact = _callingNumberController.text.trim();

    if (department.isEmpty ||
        postRank.isEmpty ||
        officialName.isEmpty ||
        batchYear.isEmpty ||
        gender.isEmpty ||
        maritalStatus.isEmpty ||
        postingCategory.isEmpty ||
        postingWorkAs.isEmpty ||
        whatsapp.isEmpty ||
        callingContact.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (department.isEmpty) 'Sub Department',
          if (postRank.isEmpty) 'Rank',
          if (officialName.isEmpty) 'Official Name',
          if (batchYear.isEmpty) 'Batch Year',
          if (gender.isEmpty) 'Gender',
          if (maritalStatus.isEmpty) 'Marital Status',
          if (postingCategory.isEmpty) 'Posting Category',
          if (postingWorkAs.isEmpty) 'Posting Work As',
          if (whatsapp.isEmpty) 'Whatsapp Number',
          if (callingContact.isEmpty) 'Calling Contact No.',
        ],
        'Complete all posting details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postRank == 'Other' && customRank.isEmpty) {
      await _markInvalidFields(
        <String>['Enter rank name'],
        'Please enter rank when you select Other.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_namePattern.hasMatch(officialName)) {
      await _markInvalidFields(
        <String>['Official Name'],
        'Enter a valid official name.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    final currentYear = DateTime.now().year;
    final batch = int.tryParse(batchYear);
    if (!_yearPattern.hasMatch(batchYear) ||
        batch == null ||
        batch < 1970 ||
        batch > currentYear) {
      await _markInvalidFields(
        <String>['Batch Year'],
        'Enter a valid batch year.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_mobilePattern.hasMatch(whatsapp) ||
        !_mobilePattern.hasMatch(callingContact)) {
      await _markInvalidFields(
        <String>[
          if (!_mobilePattern.hasMatch(whatsapp)) 'Whatsapp Number',
          if (!_mobilePattern.hasMatch(callingContact)) 'Calling Contact No.',
        ],
        'Complete all posting details with valid phone numbers.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  bool _isAcceptableStationValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return false;
    }
    return RegExp(r"^[A-Za-z0-9 .,'()/-]{3,}$").hasMatch(trimmed);
  }

  Future<bool> _validateDocumentsStep({bool showFeedback = true}) async {
    if (_selfie == null) {
      await _markInvalidFields(
        <String>['Selfie photo'],
        'Upload selfie to continue.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    return true;
  }

  Future<bool> _validateReviewStep({bool showFeedback = true}) async {
    if (!_acceptedTerms) {
      await _markInvalidFields(
        <String>['I agree to the terms and privacy policy'],
        'Please accept the terms before submitting.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!await _validateIdentityStep(showFeedback: false)) {
      await _goToStep(0);
      await _validateIdentityStep();
      return;
    }
    if (!await _validateSelfEmailStep(showFeedback: false)) {
      await _goToStep(1);
      await _validateSelfEmailStep();
      return;
    }
    if (!await _validateReferralStep(showFeedback: false)) {
      await _goToStep(2);
      await _validateReferralStep();
      return;
    }
    if (!await _validatePostingStep(showFeedback: false)) {
      await _goToStep(3);
      await _validatePostingStep();
      return;
    }
    if (!await _validateHomeStep(showFeedback: false)) {
      await _goToStep(4);
      await _validateHomeStep();
      return;
    }
    if (!await _validateDocumentsStep(showFeedback: false)) {
      await _goToStep(5);
      await _validateDocumentsStep();
      return;
    }
    if (!await _validateReviewStep(showFeedback: false)) {
      await _goToStep(6);
      await _validateReviewStep();
      return;
    }

    final unique = await _ensureIdentityNotDuplicateInCloud();
    if (!unique) {
      await _goToStep(0);
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final selfieBytes = await _selfie!.readAsBytes();
      final mediaService = widget.repository.cloudService;
      final now = DateTime.now();
      final baseName = now.microsecondsSinceEpoch;
      final selfieUrl = await mediaService.uploadImageBytes(
        bytes: selfieBytes,
        folder: 'member-docs',
        fileName: 'selfie_$baseName.jpg',
      );
      String? idCardUrl;
      if (_idCardPhoto != null) {
        final idCardBytes = await _idCardPhoto!.readAsBytes();
        idCardUrl = await mediaService.uploadImageBytes(
          bytes: idCardBytes,
          folder: 'member-docs',
          fileName: 'id_card_$baseName.jpg',
        );
      }

      if (selfieUrl == null || (_idCardPhoto != null && idCardUrl == null)) {
        final uploadError = mediaService.lastUploadError;
        final message = (uploadError == null || uploadError.isEmpty)
            ? 'Unable to upload documents to cloud. Please retry.'
            : 'Unable to upload documents to cloud: $uploadError';
        _showMessage(message);
        return;
      }

      final mobile = _mobileController.text.trim();
      final effectiveRank = _effectiveValue(_postRankController, _customRankController);
      final effectiveDepartment = _effectiveValue(_departmentController, _departmentOtherController);
      final effectivePostingState = _effectiveValue(_postingStateController, _postingStateOtherController);
      final effectivePostingDistrict = _effectiveValue(_postingDistrictController, _postingDistrictOtherController);
      final effectivePostingCategory = _effectiveValue(_postingCategoryController, _postingCategoryOtherController);
      final effectivePostingPlace = _effectiveValue(_postingLocationController, _postingLocationOtherController);
      final effectiveBatchYear = _effectiveValue(_batchYearController, _batchYearOtherController);
      final effectiveGender = _effectiveValue(_genderController, _genderOtherController);
      final effectiveMaritalStatus = _effectiveValue(_maritalStatusController, _maritalStatusOtherController);
      final effectivePostingWorkAs = _effectiveValue(_postingWorkAsController, _postingWorkAsOtherController);
      final effectiveHomeState = _effectiveValue(_homeStateController, _homeStateOtherController);
      final effectiveHomeDistrict = _effectiveValue(_homeDistrictController, _homeDistrictOtherController);
      final effectiveHomePoliceStation = _effectiveValue(_homePoliceStationController, _homePoliceStationOtherController);
      final member = Member(
        id: now.microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        mobileNumber: mobile,
        userId: 'u_$mobile',
        email: _emailController.text.trim(),
        passwordHash: widget.authService.hashPassword(mobile),
        mpin: _mpinController.text.trim(),
        referenceMobileNumber: _referenceController.text.trim(),
        referenceMemberName: _referenceMember?.name,
        selfiePath: selfieUrl,
        idCardPhotoPath: idCardUrl,
        homeDistrict: effectiveHomeDistrict,
        homeState: effectiveHomeState,
        postingDistrict: effectivePostingDistrict,
        postingState: effectivePostingState,
        postingLocation: effectivePostingPlace,
        department: effectiveDepartment,
        postRank: effectiveRank,
        officialName: _officialNameController.text.trim(),
        batchYear: effectiveBatchYear,
        gender: effectiveGender,
        maritalStatus: effectiveMaritalStatus,
        postingCategory: effectivePostingCategory,
        postingWorkAs: effectivePostingWorkAs,
        whatsappNumber: _whatsappController.text.trim(),
        callingContactNumber: _callingNumberController.text.trim(),
        postingPlaceLocation: _postingPlaceLocationController.text.trim(),
        pendingUpdatePayload: jsonEncode(<String, dynamic>{
          'biometricEnabled': _biometricVerified,
        }),
        homeVillageMohalla: _homeVillageMohallaController.text.trim(),
        homeGaliNo: _homeGaliNoController.text.trim(),
        homePostOffice: _homePostOfficeController.text.trim(),
        homePoliceStation: effectiveHomePoliceStation,
        homeTehsil: _homeTehsilController.text.trim(),
        homeVillageLocation: '',
        appointmentDate: now,
        role: 'Member',
        lastUpdated: now,
        passwordUpdatedAt: now,
        isApproved: false,
      );
      final saved = await widget.repository.saveMember(member);

      if (!saved) {
        final cloudError = mediaService.lastWriteError;
        final message = (cloudError == null || cloudError.isEmpty)
            ? 'Unable to create registration in cloud. Please retry.'
            : 'Unable to create registration in cloud: $cloudError';
        _showMessage(message);
        return;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(member);
    } catch (error) {
      _showMessage('Registration failed due to invalid or incomplete data: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _primeFormOptions() async {
    final states = await _locationSuggestions.allStates();
    final districts = await _locationSuggestions.allDistricts();
    if (!mounted) {
      return;
    }
    setState(() {
      _allStateOptions = states;
      _allDistrictOptions = districts;
      _allPostingPlaceOptions = List<String>.from(_postingPlaceOptions);
    });
    await _loadHomeDistrictOptions();
    await _loadPostingDistrictOptions();
    await _loadHomeStationOptions();
    await _loadPostingStationOptions();
  }

  Future<void> _loadHomeDistrictOptions() async {
    final state = _selectedValue(
      _homeStateController,
      _homeStateOtherController,
    );
    final districts = state.isEmpty || state == 'Other' || !_allStateOptions.contains(state)
        ? await _locationSuggestions.allDistricts()
        : await _locationSuggestions.districtsForState(state);
    if (!mounted) {
      return;
    }
    setState(() {
      _homeDistrictOptions = districts;
    });
  }

  Future<void> _loadPostingDistrictOptions() async {
    final state = _selectedValue(
      _postingStateController,
      _postingStateOtherController,
    );
    final districts = state.isEmpty || state == 'Other' || !_allStateOptions.contains(state)
        ? await _locationSuggestions.allDistricts()
        : await _locationSuggestions.districtsForState(state);
    if (!mounted) {
      return;
    }
    setState(() {
      _postingDistrictOptions = districts;
    });
  }

  Future<void> _loadHomeStationOptions() async {
    final state = _selectedValue(
      _homeStateController,
      _homeStateOtherController,
    );
    final district = _selectedValue(
      _homeDistrictController,
      _homeDistrictOtherController,
    );
    final stations = state == 'Uttar Pradesh'
        ? await _locationSuggestions.allPoliceStations(
            district: district,
          )
        : <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _allHomeStationOptions = stations;
    });
  }

  Future<void> _loadPostingPlaceOptions() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _allPostingPlaceOptions = List<String>.from(_postingPlaceOptions);
    });
  }

  Future<void> _loadPostingStationOptions() async {
    final state = _selectedValue(
      _postingStateController,
      _postingStateOtherController,
    );
    final district = _selectedValue(
      _postingDistrictController,
      _postingDistrictOtherController,
    );
    final stations = state == 'Uttar Pradesh'
        ? await _locationSuggestions.allPoliceStations(
            district: district,
          )
        : <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _allPostingStationOptions = stations;
    });
  }

  List<String> _batchYears() {
    final currentYear = DateTime.now().year;
    // Generate all years from current year down to 1970 (includes current year)
    return List<String>.generate(
      currentYear - 1969,
      (index) => (currentYear - index).toString(),
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
                    .where(
                      (item) => item.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: _fieldDecoration('Search').copyWith(
                        suffixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                allowCustomValue
                                    ? 'No matches. Select Other to enter a custom value.'
                                    : 'No matches found.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  title: Text(item),
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
                            ),
                    ),
                    if (allowCustomValue)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Other'),
                        onTap: () => Navigator.of(context).pop('Other'),
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
    if (selected.isEmpty) {
      return;
    }

    if (allowCustomValue && selected == 'Other') {
      final customValue = await _promptForCustomValue(title: title);
      if (customValue == null || customValue.trim().isEmpty) {
        return;
      }
      setState(() {
        controller.text = customValue.trim().toUpperCase();
      });
      onSelected?.call(controller.text.trim());
      return;
    }

    setState(() {
      controller.text = selected;
    });
    onSelected?.call(selected);
  }

  Future<String?> _promptForCustomValue({required String title}) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Enter $title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            inputFormatters: <TextInputFormatter>[_UpperCaseTextFormatter()],
            decoration: const InputDecoration(
              hintText: 'Type custom value',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  List<String> _pickerWithOther(List<String> options) {
    final merged = <String>[...options];
    if (!merged.any((item) => item.toLowerCase() == 'other')) {
      merged.add('Other');
    }
    return merged;
  }

  Future<void> _capturePostingLocation() async {
    setState(() {
      _capturingPostingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location service is disabled on this device.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Allow location permission to capture posting location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final link =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      setState(() {
        _postingPlaceLocationController.text = link;
        _uploadPostingGpsLater = false;
      });
      _showMessage('Posting location captured.');
    } catch (_) {
      _showMessage('Unable to capture location right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _capturingPostingLocation = false;
        });
      }
    }
  }

}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
