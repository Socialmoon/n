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
  static const Color _ink = Color(0xFF0F2638);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _gold = Color(0xFFD4994A);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _surface = Color(0xFFF8FAFC);

  static const List<String> _steps = <String>[
    'Basic Detail',
    'Verify Self Email',
    'Verify Referral Email',
    'Posting Details',
    'Service Profile',
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
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
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

  static const List<String> _rankOptions = <String>[
    'Constable',
    'Head Constable',
    'Computer Operator',
    'ASI',
    'SI',
    'Inspector',
    'DSP',
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
    'CO',
    'Office Incharge',
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
      backgroundColor: _surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _buildScreenHeader(keyboardOpen),
            Padding(
              padding: EdgeInsets.fromLTRB(20, keyboardOpen ? 4 : 10, 20, 0),
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
                  _buildServiceProfileStep(),
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
    );
  }

  Widget _buildScreenHeader(bool keyboardOpen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: keyboardOpen ? 0 : 64,
      margin: EdgeInsets.fromLTRB(20, keyboardOpen ? 0 : 6, 20, 0),
      child: keyboardOpen
          ? const SizedBox.shrink()
          : Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: _ink,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'New Registration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fill each step carefully to submit your profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8896A4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepStrip() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 32,
          child: Row(
            children: List<Widget>.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final idx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: idx < _currentStep
                          ? _accent
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx < _currentStep;
              final active = idx == _currentStep;
              final size = active ? 30.0 : 24.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _accent : (active ? _ink : Colors.white),
                  border: Border.all(
                    color: done
                        ? _accent
                        : (active ? _ink : const Color(0xFFCBD5E1)),
                    width: active ? 2.5 : 1.5,
                  ),
                  boxShadow: active
                      ? <BoxShadow>[
                          BoxShadow(
                            color: _ink.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: active ? 13 : 11,
                            fontWeight: FontWeight.w700,
                            color:
                                active ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _steps[_currentStep],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepPage(
      title: 'Basic detail',
      subtitle: 'Enter your personal information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCard(
            icon: Icons.badge_outlined,
            heading: 'Identity profile',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                  obscureText: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            icon: Icons.fingerprint,
            heading: 'Biometric verification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildFingerprintOption(),
                const SizedBox(height: 6),
                Text(
                  _biometricSupported
                      ? 'Use device biometrics for quick login after approval.'
                      : 'Biometric verification is unavailable on this device.',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8896A4)),
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
      subtitle: 'We\'ll send a 6-digit OTP to confirm your email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCard(
            icon: Icons.email_outlined,
            heading: 'Self email OTP verification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField(
                  _emailController,
                  'Self Email Address',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailVerified ||
                        _emailOtpSent ||
                        _emailOtpController.text.isNotEmpty) {
                      setState(() {
                        _emailVerified = false;
                        _emailOtpSent = false;
                        _showOtpSendButton = false;
                        _emailOtpController.clear();
                      });
                    }
                  },
                ),
                if (_emailVerified)
                  _buildStatusChip(
                      Icons.check_circle_rounded, 'Email verified', true)
                else ...<Widget>[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          _sendingEmailOtp ? null : _sendRegistrationEmailOtp,
                      icon: _sendingEmailOtp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_sendingEmailOtp
                          ? 'Sending OTP...'
                          : (_emailOtpSent && _otpResendSeconds > 0
                              ? 'Resend in $_otpResendSeconds s'
                              : (_emailOtpSent ? 'Resend OTP' : 'Send OTP'))),
                    ),
                  ),
                ],
                if (_emailOtpSent && !_emailVerified) ...<Widget>[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_verifyingEmailOtp && !_emailVerified,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (value) {
                      if (value.trim().length == 6 && !_verifyingEmailOtp) {
                        unawaited(_verifyRegistrationEmail());
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Email OTP',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: _verifyingEmailOtp
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
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
      title: 'Verify referral',
      subtitle: 'An existing member must verify your registration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildCard(
            icon: Icons.people_alt_outlined,
            heading: 'Referring member',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTextField(
                  _referenceController,
                  'Referring Mobile No.',
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  digitsOnly: true,
                  onChanged: (_) => _syncReferenceMember(),
                ),
                if (_referenceMember != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _buildReferenceMemberCard(_referenceMember!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            icon: Icons.mark_email_read_outlined,
            heading: 'Referral email OTP',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_referenceEmailVerified)
                  _buildStatusChip(
                      Icons.check_circle_rounded, 'Referral OTP verified', true)
                else ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _sendingReferenceEmailOtp
                          ? null
                          : _sendReferenceEmailOtp,
                      icon: _sendingReferenceEmailOtp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_sendingReferenceEmailOtp
                          ? 'Sending OTP...'
                          : (_referenceEmailOtpSent &&
                                  _referenceOtpResendSeconds > 0
                              ? 'Resend in $_referenceOtpResendSeconds s'
                              : (_referenceEmailOtpSent
                                  ? 'Resend OTP'
                                  : 'Send OTP'))),
                    ),
                  ),
                ],
                if (_referenceEmailOtpSent &&
                    !_referenceEmailVerified) ...<Widget>[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _referenceEmailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_verifyingReferenceEmailOtp &&
                        !_referenceEmailVerified,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    onChanged: (value) {
                      if (value.trim().length == 6 &&
                          !_verifyingReferenceEmailOtp) {
                        unawaited(_verifyReferenceEmailOtp());
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Referral OTP',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.password_outlined),
                      suffixIcon: _verifyingReferenceEmailOtp
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
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
      subtitle: 'Your permanent residential address',
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
                      _homeStateOtherController.clear();
                    });
                    unawaited(_loadHomeDistrictOptions());
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              if (_homeStateController.text.trim() == 'Other')
                _buildTextField(_homeStateOtherController, 'Enter state name',
                    uppercase: true),
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
                      _homeDistrictOtherController.clear();
                    });
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              if (_homeDistrictController.text.trim() == 'Other')
                _buildTextField(
                    _homeDistrictOtherController, 'Enter district name',
                    uppercase: true),
              _buildTextField(_homeTehsilController, 'Home Tehsil',
                  isRequired: true),
              _buildTextField(_homePostOfficeController, 'Post Office',
                  isRequired: true),
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
                  onSelected: (value) {
                    if (value != 'Other') {
                      _homePoliceStationOtherController.clear();
                    }
                  },
                ),
              ),
              if (_homePoliceStationController.text.trim() == 'Other')
                _buildTextField(_homePoliceStationOtherController,
                    'Enter police station name',
                    uppercase: true),
              _buildTextField(
                  _homeVillageMohallaController, 'Village / Mohalla',
                  isRequired: true),
              _buildTextField(_homeGaliNoController, 'Gali No.',
                  isRequired: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostingDetailsStep() {
    return _buildStepPage(
      title: 'Posting details',
      subtitle: 'Your current posting location information',
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
                      _postingStateOtherController.clear();
                    });
                    unawaited(_loadPostingDistrictOptions());
                    unawaited(_loadPostingStationOptions());
                    unawaited(_loadPostingPlaceOptions());
                  },
                ),
              ),
              if (_postingStateController.text.trim() == 'Other')
                _buildTextField(
                    _postingStateOtherController, 'Enter state name',
                    uppercase: true),
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
                      _postingDistrictOtherController.clear();
                    });
                    unawaited(_loadPostingStationOptions());
                  },
                ),
              ),
              if (_postingDistrictController.text.trim() == 'Other')
                _buildTextField(
                    _postingDistrictOtherController, 'Enter district name',
                    uppercase: true),
              _buildSelectionField(
                _departmentController,
                'Sub Department',
                isRequired: true,
                hint: 'Tap to choose sub department',
                onTap: () => _pickFromList(
                  title: 'Select Sub Department',
                  options: _subDepartments,
                  controller: _departmentController,
                  onSelected: (value) {
                    if (value != 'Others') {
                      _departmentOtherController.clear();
                    }
                  },
                ),
              ),
              if (_departmentController.text.trim() == 'Others')
                _buildTextField(
                    _departmentOtherController, 'Enter department name',
                    uppercase: true),
              _buildSelectionField(
                _postingCategoryController,
                'Posting Category',
                isRequired: true,
                hint: 'Tap to choose posting category',
                onTap: () => _pickFromList(
                  title: 'Select Posting Category',
                  options: _postingCategories,
                  controller: _postingCategoryController,
                  onSelected: (value) {
                    setState(() {
                      _postingLocationController.clear();
                      _postingLocationOtherController.clear();
                      _postingCategoryOtherController.clear();
                    });
                    if (value == 'Police Station') {
                      unawaited(_loadPostingStationOptions());
                    } else {
                      unawaited(_loadPostingPlaceOptions());
                    }
                  },
                ),
              ),
              if (_postingCategoryController.text.trim() == 'Other')
                _buildTextField(
                    _postingCategoryOtherController, 'Enter posting category',
                    uppercase: true),
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
                  onPressed: _capturingPostingLocation
                      ? null
                      : _capturePostingLocation,
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
        ],
      ),
    );
  }

  Widget _buildServiceProfileStep() {
    return _buildStepPage(
      title: 'Service profile',
      subtitle: 'Your professional rank and contact details',
      child: Column(
        children: <Widget>[
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
              _buildSelectionField(
                _postRankController,
                'Rank',
                isRequired: true,
                hint: 'Tap to choose rank',
                onTap: () => _pickFromList(
                  title: 'Select Rank',
                  options: _rankOptions,
                  controller: _postRankController,
                  onSelected: (value) {
                    if (value != 'Other') {
                      _customRankController.clear();
                    }
                  },
                ),
              ),
              if (_postRankController.text.trim() == 'Other')
                _buildTextField(_customRankController, 'Enter rank name',
                    uppercase: true),
              _buildSelectionField(
                _batchYearController,
                'Batch Year',
                isRequired: true,
                hint: 'Tap to choose batch year',
                onTap: () => _pickFromList(
                  title: 'Select Batch Year',
                  options: _batchYears(),
                  controller: _batchYearController,
                ),
              ),
              _buildSelectionField(
                _genderController,
                'Gender',
                isRequired: true,
                hint: 'Tap to choose gender',
                onTap: () => _pickFromList(
                  title: 'Select Gender',
                  options: _genderOptions,
                  controller: _genderController,
                  onSelected: (value) {
                    if (value != 'Other') {
                      _genderOtherController.clear();
                    }
                  },
                ),
              ),
              if (_genderController.text.trim() == 'Other')
                _buildTextField(_genderOtherController, 'Enter gender',
                    uppercase: true),
              _buildSelectionField(
                _maritalStatusController,
                'Marital Status',
                isRequired: true,
                hint: 'Tap to choose marital status',
                onTap: () => _pickFromList(
                  title: 'Select Marital Status',
                  options: _maritalStatusOptions,
                  controller: _maritalStatusController,
                  onSelected: (value) {
                    if (value != 'Other') {
                      _maritalStatusOtherController.clear();
                    }
                  },
                ),
              ),
              if (_maritalStatusController.text.trim() == 'Other')
                _buildTextField(
                    _maritalStatusOtherController, 'Enter marital status',
                    uppercase: true),
              _buildSelectionField(
                _postingWorkAsController,
                'Posting Work As',
                isRequired: true,
                hint: 'Tap to choose work type',
                onTap: () => _pickFromList(
                  title: 'Select Posting Work As',
                  options: _postingWorkOptions,
                  controller: _postingWorkAsController,
                  onSelected: (value) {
                    if (value != 'Other') {
                      _postingWorkAsOtherController.clear();
                    }
                  },
                ),
              ),
              if (_postingWorkAsController.text.trim() == 'Other')
                _buildTextField(
                    _postingWorkAsOtherController, 'Enter posting work type',
                    uppercase: true),
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
    final isPoliceStation =
        _postingCategoryController.text.trim() == 'Police Station';
    final options =
        isPoliceStation ? _allPostingStationOptions : _allPostingPlaceOptions;
    final label =
        isPoliceStation ? 'Posting Police Station' : 'Posting Place Name';
    final hint = isPoliceStation
        ? 'Tap to choose police station'
        : 'Tap to choose place name';
    final title = isPoliceStation
        ? 'Select Posting Police Station'
        : 'Select Posting Place Name';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildSelectionField(
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
            onSelected: (value) {
              if (value != 'Other') {
                _postingLocationOtherController.clear();
              }
            },
          ),
        ),
        if (_postingLocationController.text.trim() == 'Other')
          _buildTextField(
              _postingLocationOtherController, 'Enter posting place name',
              uppercase: true),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return _buildStepPage(
      title: 'Photos',
      subtitle: 'Upload your selfie and ID proof',
      child: Column(
        children: <Widget>[
          _buildUploadTile(
            title: 'Selfie photo',
            subtitle: 'Take a clear selfie for admin verification',
            icon: Icons.camera_alt_outlined,
            onTap: _pickSelfie,
            hasFile: _selfie != null,
          ),
          if (_selfie != null) _buildImagePreview(_selfie!),
          const SizedBox(height: 14),
          _buildUploadTile(
            title: 'ID proof photo',
            subtitle: 'Upload a photo of your service ID card',
            icon: Icons.badge_outlined,
            onTap: _pickIdCardPhoto,
            hasFile: _idCardPhoto != null,
          ),
          if (_idCardPhoto != null) _buildImagePreview(_idCardPhoto!),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepPage(
      title: 'Review & submit',
      subtitle: 'Verify all details before final submission',
      child: Column(
        children: <Widget>[
          _buildCard(
            icon: Icons.person_outlined,
            heading: 'Personal',
            child: Column(
              children: <Widget>[
                _buildSummaryRow('Full name', _nameController.text.trim()),
                _buildSummaryRow('Self email', _emailController.text.trim()),
                _buildSummaryRow('Mobile', _mobileController.text.trim()),
                _buildSummaryRow('M-PIN', '******'),
                _buildSummaryRow('Biometric',
                    _biometricVerified ? 'Verified' : 'Not verified'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.people_alt_outlined,
            heading: 'Referral',
            child: Column(
              children: <Widget>[
                _buildSummaryRow(
                    'Referring mobile', _referenceController.text.trim()),
                _buildSummaryRow(
                    'Referring email', _referenceMember?.email?.trim() ?? '-'),
                _buildSummaryRow('Ref email OTP',
                    _referenceEmailVerified ? 'Verified' : 'Pending'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.location_on_outlined,
            heading: 'Posting',
            child: Column(
              children: <Widget>[
                _buildSummaryRow(
                    'State',
                    _effectiveValue(
                        _postingStateController, _postingStateOtherController)),
                _buildSummaryRow(
                    'District',
                    _effectiveValue(_postingDistrictController,
                        _postingDistrictOtherController)),
                _buildSummaryRow(
                    'Category',
                    _effectiveValue(_postingCategoryController,
                        _postingCategoryOtherController)),
                _buildSummaryRow(
                    'Place',
                    _effectiveValue(_postingLocationController,
                        _postingLocationOtherController)),
                _buildSummaryRow(
                    'GPS',
                    _postingPlaceLocationController.text.trim().isEmpty
                        ? (_uploadPostingGpsLater
                            ? 'Will upload later'
                            : 'Not captured')
                        : 'Captured'),
                _buildSummaryRow(
                    'Sub dept',
                    _effectiveValue(
                        _departmentController, _departmentOtherController)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.work_outline_rounded,
            heading: 'Service Profile',
            child: Column(
              children: <Widget>[
                _buildSummaryRow(
                    'Official name', _officialNameController.text.trim()),
                _buildSummaryRow(
                    'Rank',
                    _effectiveValue(
                        _postRankController, _customRankController)),
                _buildSummaryRow(
                    'Batch year',
                    _effectiveValue(
                        _batchYearController, _batchYearOtherController)),
                _buildSummaryRow('Gender',
                    _effectiveValue(_genderController, _genderOtherController)),
                _buildSummaryRow(
                    'Marital status',
                    _effectiveValue(_maritalStatusController,
                        _maritalStatusOtherController)),
                _buildSummaryRow(
                    'Work type',
                    _effectiveValue(_postingWorkAsController,
                        _postingWorkAsOtherController)),
                _buildSummaryRow('WhatsApp', _whatsappController.text.trim()),
                _buildSummaryRow(
                    'Calling', _callingNumberController.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildCard(
            icon: Icons.home_outlined,
            heading: 'Home',
            child: Column(
              children: <Widget>[
                _buildSummaryRow(
                    'State',
                    _effectiveValue(
                        _homeStateController, _homeStateOtherController)),
                _buildSummaryRow(
                    'District',
                    _effectiveValue(
                        _homeDistrictController, _homeDistrictOtherController)),
                _buildSummaryRow(
                    'Police station',
                    _effectiveValue(_homePoliceStationController,
                        _homePoliceStationOtherController)),
                _buildSummaryRow(
                    'Village', _homeVillageMohallaController.text.trim()),
                _buildSummaryRow(
                    'Post office', _homePostOfficeController.text.trim()),
                _buildSummaryRow('Gali no.', _homeGaliNoController.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFDDB3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded, size: 18, color: _gold),
                    SizedBox(width: 8),
                    Text(
                      'Important',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, color: _ink),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registration remains pending until admin approval.',
                  style: TextStyle(
                      fontSize: 13, height: 1.4, color: Color(0xFF4A5568)),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsPrivacyScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: const Text('Read terms and privacy'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _acceptedTerms,
                  activeColor: _accent,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  title: const Text(
                    'I agree to the terms and privacy policy',
                    style: TextStyle(fontSize: 14),
                  ),
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
    String? subtitle,
    required Widget child,
  }) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8896A4),
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool hasFile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    hasFile ? const Color(0xFFE8F5E9) : const Color(0xFFEDF2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(hasFile ? Icons.check_rounded : icon,
                  color: hasFile ? const Color(0xFF2E7D32) : _ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _ink)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8896A4))),
                    ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.refresh_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFF8896A4),
            ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8896A4),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom + 6 : 14.0;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitting ? null : _previousStep,
                child: const Text('Back',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    _currentStep == _steps.length - 1 ? _accent : _ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: const Color(0xFFA0AEC0),
              ),
              onPressed: _submitting ? null : _handlePrimaryAction,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      _currentStep == _steps.length - 1
                          ? 'Submit registration'
                          : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.fingerprint_outlined, color: Color(0xFF94A3B8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fingerprint option is not available on this device.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _biometricVerified
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _biometricVerified
              ? const Color(0xFF81C784)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _biometricVerified ? Icons.verified_rounded : Icons.fingerprint,
            color: _biometricVerified ? const Color(0xFF2E7D32) : _ink,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _biometricVerified
                  ? 'Fingerprint verified successfully'
                  : 'Verify fingerprint to enable biometric login',
              style: TextStyle(
                color: _biometricVerified ? const Color(0xFF2E7D32) : _ink,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  _biometricVerified ? const Color(0xFF2E7D32) : _ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: _checkingBiometric ? null : _verifyFingerprint,
            child: Text(_checkingBiometric
                ? '...'
                : (_biometricVerified ? 'Re-check' : 'Verify')),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String heading,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _ink, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEDF2F7)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String label, bool success) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: success ? const Color(0xFF81C784) : const Color(0xFFFFCC80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon,
              size: 18,
              color:
                  success ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color:
                  success ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
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
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    final id = fieldId ?? label;
    return TextFormField(
      key: _fieldKey(id),
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
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
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: initiallyExpanded,
          title: Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _ink, fontSize: 15),
          ),
          children: children,
        ),
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

  InputDecoration _fieldDecoration(
    String label, {
    bool isRequired = false,
    String? errorText,
  }) {
    final labelText = isRequired ? '$label *' : label;
    return InputDecoration(
      labelText: labelText,
      floatingLabelStyle:
          const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      errorText: errorText,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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

  Future<void> _markInvalidFields(List<String> fieldIds, String firstMessage,
      {bool showMessage = true, bool scroll = true}) async {
    setState(() {
      _invalidFieldIds
        ..clear()
        ..addAll(fieldIds);
      _fieldErrors
        ..clear()
        ..addEntries(
            fieldIds.map((id) => MapEntry<String, String>(id, firstMessage)));
    });
    if (showMessage) {
      _showMessage(firstMessage, isError: true);
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
    if (_officialNameEditedByUser &&
        _officialNameController.text.trim().isNotEmpty) {
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
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.name,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, color: _ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.email ?? 'No email on file'} • ${member.role}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8896A4)),
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
      _showMessage('Enter a valid referral mobile number first.',
          isError: true);
      return;
    }

    if (email.isEmpty) {
      _showMessage('No email is attached to this referral mobile number.',
          isError: true);
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
        _showMessage(dispatch.error ?? 'Unable to send referral OTP.',
            isError: true);
        return;
      }

      _referenceOtpResendTimer?.cancel();
      setState(() {
        _sendingReferenceEmailOtp = false;
        _referenceEmailOtpSent = true;
        _referenceOtpResendSeconds = 600;
      });

      _referenceOtpResendTimer =
          Timer.periodic(const Duration(seconds: 1), (_) {
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
      _showMessage('Unable to send referral OTP right now.', isError: true);
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

    try {
      final verified = await _emailOtpService.verifyOtp(email: email, otp: otp);

      if (!mounted) {
        return false;
      }

      setState(() {
        _verifyingReferenceEmailOtp = false;
      });

      if (!verified) {
        _showMessage('Invalid or expired referral OTP.', isError: true);
        return false;
      }

      setState(() {
        _referenceEmailVerified = true;
      });
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _verifyingReferenceEmailOtp = false;
      });
      _showMessage('Unable to verify referral OTP right now. Please retry.',
          isError: true);
      return false;
    }
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
      _showMessage('Fingerprint is not available on this device.',
          isError: true);
      return;
    }

    setState(() {
      _checkingBiometric = true;
    });

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason:
            'Verify fingerprint for quick login after registration',
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
      _showMessage('Fingerprint verification is unavailable on this device.',
          isError: true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to verify fingerprint right now.', isError: true);
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
      if (!await _validateServiceStep()) {
        return;
      }
      await _goToStep(5);
      return;
    }

    if (_currentStep == 5) {
      if (!await _validateHomeStep()) {
        return;
      }
      await _goToStep(6);
      return;
    }

    if (_currentStep == 6) {
      if (!await _validateDocumentsStep()) {
        return;
      }
      await _goToStep(7);
      return;
    }

    if (_currentStep == 7) {
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
    if (RegExp(r'^(\d)\1{5}$').hasMatch(mpin)) {
      await _markInvalidFields(
        <String>['Security M-PIN'],
        'M-PIN is too weak. Avoid repeating digits like 111111.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (mpin == '123456' || mpin == '654321') {
      await _markInvalidFields(
        <String>['Security M-PIN'],
        'M-PIN is too common. Choose a stronger PIN.',
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
      _showMessage('Please complete biometric verification on this device.',
          isError: true);
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
      _showMessage('Verify your self email OTP before continuing.',
          isError: true);
      return false;
    }
    return true;
  }

  Future<bool> _ensureIdentityNotDuplicateInCloud() async {
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    try {
      final byMobile = await widget.repository.fetchByMobileFromCloud(mobile);
      if (byMobile != null) {
        _showMessage('Mobile number already registered in system.',
            isError: true);
        return false;
      }

      final byEmail = await widget.repository.fetchByEmailFromCloud(email);
      if (byEmail != null) {
        _showMessage('Email already registered in system.', isError: true);
        return false;
      }
      return true;
    } catch (_) {
      _showMessage('Unable to verify existing registration right now.',
          isError: true);
      return false;
    }
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

    if (!_mobilePattern.hasMatch(mobile)) {
      await _markInvalidFields(
        <String>['Referring Mobile No.'],
        'Referring mobile must be 10 digits.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (mobile == _mobileController.text.trim()) {
      await _markInvalidFields(
        <String>['Referring Mobile No.'],
        'Referring mobile cannot be your own mobile number.',
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
      await _markInvalidFields(
          <String>['Enter OTP'], 'Enter valid 6 digit OTP.');
      return false;
    }

    final email = _emailController.text.trim();
    setState(() {
      _verifyingEmailOtp = true;
    });

    try {
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
        await _markInvalidFields(
            <String>['Enter OTP'], 'Invalid or expired email OTP.');
        return false;
      }

      setState(() {
        _emailVerified = true;
      });
      return true;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _verifyingEmailOtp = false;
      });
      _showMessage('Unable to verify email OTP right now. Please try again.',
          isError: true);
      return false;
    }
  }

  Future<void> _sendRegistrationEmailOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Enter a valid email address first.', isError: true);
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
        _showMessage(dispatch.error ?? 'Unable to send email OTP.',
            isError: true);
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
      _showMessage('Unable to send email OTP right now. Please try again.',
          isError: true);
    }
  }

  Future<bool> _validateHomeStep({bool showFeedback = true}) async {
    final homeState =
        _selectedValue(_homeStateController, _homeStateOtherController);
    final homeDistrict =
        _effectiveValue(_homeDistrictController, _homeDistrictOtherController);
    final homeVillageMohalla = _homeVillageMohallaController.text.trim();
    final homeGaliNo = _homeGaliNoController.text.trim();
    final homePoliceStation = _effectiveValue(
        _homePoliceStationController, _homePoliceStationOtherController);
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
        'Complete all home details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (homeState.length < 2 || homeDistrict.length < 2) {
      await _markInvalidFields(
        <String>[
          if (homeState.length < 2) 'Home State',
          if (homeDistrict.length < 2) 'Home District'
        ],
        'Enter a valid home state and district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _validatePostingStep({bool showFeedback = true}) async {
    final postingState =
        _selectedValue(_postingStateController, _postingStateOtherController);
    final postingDistrict = _effectiveValue(
        _postingDistrictController, _postingDistrictOtherController);
    final department = _departmentController.text.trim();
    final postingCategory = _effectiveValue(
        _postingCategoryController, _postingCategoryOtherController);
    final postingPlace = _effectiveValue(
        _postingLocationController, _postingLocationOtherController);
    final postingGps = _postingPlaceLocationController.text.trim();

    if (postingState.isEmpty ||
        postingDistrict.isEmpty ||
        department.isEmpty ||
        postingCategory.isEmpty ||
        postingPlace.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (postingState.isEmpty) 'Posting State',
          if (postingDistrict.isEmpty) 'Posting District',
          if (department.isEmpty) 'Sub Department',
          if (postingCategory.isEmpty) 'Posting Category',
          if (postingPlace.isEmpty) 'Posting Place Name',
        ],
        'Complete all posting location details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingState.length < 2 || postingDistrict.length < 2) {
      await _markInvalidFields(
        <String>[
          if (postingState.length < 2) 'Posting State',
          if (postingDistrict.length < 2) 'Posting District'
        ],
        'Enter a valid posting state and district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (_departmentController.text.trim() == 'Others' &&
        _departmentOtherController.text.trim().isEmpty) {
      await _markInvalidFields(
        <String>['Enter department name'],
        'Please enter department name when you select Others.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (_postingCategoryController.text.trim() == 'Other' &&
        _postingCategoryOtherController.text.trim().isEmpty) {
      await _markInvalidFields(
        <String>['Enter posting category'],
        'Please enter posting category when you select Other.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (_postingCategoryController.text.trim() == 'Police Station') {
      if (postingPlace.length < 3) {
        await _markInvalidFields(
          <String>['Posting Place Name'],
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
    final postRank = _postRankController.text.trim();
    final customRank = _customRankController.text.trim();
    final officialName = _officialNameController.text.trim();
    final batchYear = _batchYearController.text.trim();
    final gender = _genderController.text.trim();
    final maritalStatus = _maritalStatusController.text.trim();
    final postingWorkAs = _postingWorkAsController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final callingContact = _callingNumberController.text.trim();

    if (postRank.isEmpty ||
        officialName.isEmpty ||
        batchYear.isEmpty ||
        gender.isEmpty ||
        maritalStatus.isEmpty ||
        postingWorkAs.isEmpty ||
        whatsapp.isEmpty ||
        callingContact.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (postRank.isEmpty) 'Rank',
          if (officialName.isEmpty) 'Official Name',
          if (batchYear.isEmpty) 'Batch Year',
          if (gender.isEmpty) 'Gender',
          if (maritalStatus.isEmpty) 'Marital Status',
          if (postingWorkAs.isEmpty) 'Posting Work As',
          if (whatsapp.isEmpty) 'Whatsapp Number',
          if (callingContact.isEmpty) 'Calling Contact No.',
        ],
        'Complete all service profile details.',
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

    if (gender == 'Other' && _genderOtherController.text.trim().isEmpty) {
      await _markInvalidFields(
        <String>['Enter gender'],
        'Please enter gender when you select Other.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (maritalStatus == 'Other' &&
        _maritalStatusOtherController.text.trim().isEmpty) {
      await _markInvalidFields(
        <String>['Enter marital status'],
        'Please enter marital status when you select Other.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingWorkAs == 'Other' &&
        _postingWorkAsOtherController.text.trim().isEmpty) {
      await _markInvalidFields(
        <String>['Enter posting work type'],
        'Please enter work type when you select Other.',
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? const Color(0xFFDC2626) : _ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
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
    if (!await _validateServiceStep(showFeedback: false)) {
      await _goToStep(4);
      await _validateServiceStep();
      return;
    }
    if (!await _validateHomeStep(showFeedback: false)) {
      await _goToStep(5);
      await _validateHomeStep();
      return;
    }
    if (!await _validateDocumentsStep(showFeedback: false)) {
      await _goToStep(6);
      await _validateDocumentsStep();
      return;
    }
    if (!await _validateReviewStep(showFeedback: false)) {
      await _goToStep(7);
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
        _showMessage(message, isError: true);
        return;
      }

      final mobile = _mobileController.text.trim();
      final effectiveRank =
          _effectiveValue(_postRankController, _customRankController);
      final effectiveDepartment =
          _effectiveValue(_departmentController, _departmentOtherController);
      final effectivePostingState = _effectiveValue(
          _postingStateController, _postingStateOtherController);
      final effectivePostingDistrict = _effectiveValue(
          _postingDistrictController, _postingDistrictOtherController);
      final effectivePostingCategory = _effectiveValue(
          _postingCategoryController, _postingCategoryOtherController);
      final effectivePostingPlace = _effectiveValue(
          _postingLocationController, _postingLocationOtherController);
      final effectiveBatchYear =
          _effectiveValue(_batchYearController, _batchYearOtherController);
      final effectiveGender =
          _effectiveValue(_genderController, _genderOtherController);
      final effectiveMaritalStatus = _effectiveValue(
          _maritalStatusController, _maritalStatusOtherController);
      final effectivePostingWorkAs = _effectiveValue(
          _postingWorkAsController, _postingWorkAsOtherController);
      final effectiveHomeState =
          _effectiveValue(_homeStateController, _homeStateOtherController);
      final effectiveHomeDistrict = _effectiveValue(
          _homeDistrictController, _homeDistrictOtherController);
      final effectiveHomePoliceStation = _effectiveValue(
          _homePoliceStationController, _homePoliceStationOtherController);
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
        _showMessage(message, isError: true);
        return;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(member);
    } catch (error) {
      _showMessage(
          'Registration failed due to invalid or incomplete data: $error',
          isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _primeFormOptions() async {
    try {
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
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to load location options. Please try again.',
            isError: true);
      }
    }
  }

  Future<void> _loadHomeDistrictOptions() async {
    final state = _selectedValue(
      _homeStateController,
      _homeStateOtherController,
    );
    final districts =
        state.isEmpty || state == 'Other' || !_allStateOptions.contains(state)
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
    final districts =
        state.isEmpty || state == 'Other' || !_allStateOptions.contains(state)
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final searchController = TextEditingController();
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.trim().isEmpty
                ? options
                : options
                    .where(
                      (item) =>
                          item.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: _fieldDecoration('Search').copyWith(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setSheetState(() {
                                    query = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.search_off_rounded,
                                      size: 40, color: Color(0xFFA0AEC0)),
                                  const SizedBox(height: 8),
                                  Text(
                                    allowCustomValue
                                        ? 'No matches. Tap Other below.'
                                        : 'No matches found.',
                                    style: const TextStyle(
                                        color: Color(0xFF8896A4)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isSelected =
                                    controller.text.trim() == item;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isSelected ? _accent : _ink,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_rounded,
                                          color: _accent, size: 20)
                                      : null,
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
                            ),
                    ),
                    if (allowCustomValue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Enter custom value'),
                            onPressed: () => Navigator.of(context).pop('Other'),
                          ),
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
    if (selected.isEmpty) {
      return;
    }

    if (allowCustomValue && selected == 'Other') {
      setState(() {
        controller.text = 'Other';
      });
      onSelected?.call('Other');
      return;
    }

    setState(() {
      controller.text = selected;
    });
    onSelected?.call(selected);
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
        _showMessage('Location service is disabled on this device.',
            isError: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Allow location permission to capture posting location.',
            isError: true);
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
      _showMessage('Unable to capture location right now. Please try again.',
          isError: true);
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
