import 'package:flutter/material.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  static const Color _ink = Color(0xFF0F2638);
  static const Color _gold = Color(0xFFD4994A);
  static const Color _surface = Color(0xFFF8FAFC);

  bool _hindi = false;

  @override
  Widget build(BuildContext context) {
    final sections = _hindi ? _sectionsHi : _sectionsEn;
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _ink,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(Icons.translate_rounded, size: 18, color: _gold),
                  label: Text(
                    _hindi ? 'English' : 'हिन्दी',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1A3A52),
                  side: const BorderSide(color: _gold),
                  onPressed: () => setState(() => _hindi = !_hindi),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF0A1A2E),
                      Color(0xFF0F2638),
                      Color(0xFF1A3A54),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              const Color(0x15FFFFFF),
                              const Color(0x00FFFFFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: <Color>[
                              const Color(0x10D4994A),
                              const Color(0x00D4994A),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x20FFFFFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFFD4994A),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _hindi ? 'उपयोगकर्ता गाइड' : 'User Guide',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hindi
                                  ? 'इस ऐप के बारे में सब कुछ जानें'
                                  : 'Everything you need to know about using this app',
                              style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: _purposeCard(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              sections
                  .map(
                    (section) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _GuideSection(section: section),
                    ),
                  )
                  .toList(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
              child: _footerCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _purposeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFF8EE), Color(0xFFFFF4E0)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDDB3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.handshake_rounded, color: _gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hindi ? 'हमारा उद्देश्य' : 'Our Purpose',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _hindi
                ? 'यह ऐप सदस्यों के बीच मजबूत रिश्ते बनाने, एक विश्वसनीय सहायता नेटवर्क '
                    'प्रदान करने और जरूरत के समय एक-दूसरे की मदद करने के लिए बनाया गया है। '
                    'चाहे कोई आपातकाल हो, नई जगह स्थानांतरण हो, या बस जुड़े रहना हो — '
                    'यह प्लेटफ़ॉर्म सदस्यों को एक परिवार की तरह एक साथ लाता है।'
                : 'This app is built to strengthen bonds between members, '
                    'provide a trusted support network, and help each other '
                    'in times of need. Whether it is an emergency, a transfer '
                    'to a new city, or simply staying connected — this platform '
                    'brings members together as one family.',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4A5568),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hindi
                ? 'हर सुविधा सदस्यों की सुरक्षा, सहयोग और आपसी सहायता को '
                    'बढ़ावा देने के लिए डिज़ाइन की गई है।'
                : 'Every feature is designed to promote safety, cooperation, '
                    'and mutual support among members across the state.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A88),
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.favorite_rounded,
              color: Color(0xFFE57373), size: 28),
          const SizedBox(height: 10),
          Text(
            _hindi
                ? 'हर सदस्य के लिए प्यार से बनाया गया'
                : 'Built with care for every member',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _hindi
                ? 'अगर आपको कोई समस्या आती है या कोई सुझाव है, तो कृपया '
                    'सेटिंग्स में बग रिपोर्ट विकल्प से संपर्क करें। आपकी प्रतिक्रिया '
                    'इस प्लेटफ़ॉर्म को सबके लिए बेहतर बनाने में मदद करती है।'
                : 'If you face any issue or have suggestions, please reach '
                    'out via the Bug Report option in Settings. Your feedback '
                    'helps us improve this platform for everyone.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7A88),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _SectionData {
  const _SectionData({
    required this.icon,
    required this.title,
    required this.color,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String description;
  final List<_FeatureItem> features;
}

class _FeatureItem {
  const _FeatureItem(this.title, this.detail);

  final String title;
  final String detail;
}

// ---------------------------------------------------------------------------
// Section widget
// ---------------------------------------------------------------------------

class _GuideSection extends StatefulWidget {
  const _GuideSection({required this.section});

  final _SectionData section;

  @override
  State<_GuideSection> createState() => _GuideSectionState();
}

class _GuideSectionState extends State<_GuideSection> {
  bool _expanded = false;

  static const Color _ink = Color(0xFF0F2638);

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x08000000),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, color: s.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8896A4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable feature list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Text(
                    s.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7A88),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...s.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${f.title}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: f.detail,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7A88),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content data
// ---------------------------------------------------------------------------

const List<_SectionData> _sectionsEn = <_SectionData>[
  _SectionData(
    icon: Icons.person_add_alt_1_rounded,
    title: 'Registration & Getting Started',
    color: Color(0xFF2563EB),
    description:
        'How to create your account and join the network. The 8-step registration flow ensures every member is genuine and verified.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Create Account',
        'Enter your name, mobile number, and set a 6-digit security M-PIN. '
            'Upload a selfie and optionally an ID card photo.',
      ),
      _FeatureItem(
        'Email Verification',
        'Verify your personal email address with a one-time OTP code '
            'sent to your inbox.',
      ),
      _FeatureItem(
        'Reference Verification',
        'An existing member must verify your registration via their '
            'email OTP. This ensures trust in the network.',
      ),
      _FeatureItem(
        'Posting Details',
        'Enter your current posting state, district, department, '
            'posting category, and exact posting place with GPS.',
      ),
      _FeatureItem(
        'Service Profile',
        'Fill in your rank, batch year, official name, gender, '
            'marital status, and contact numbers (WhatsApp & calling).',
      ),
      _FeatureItem(
        'Home Details',
        'Enter your permanent home address — state, district, '
            'tehsil, post office, police station, village, and gali number.',
      ),
      _FeatureItem(
        'Admin Approval',
        'After submitting, your profile is reviewed by an admin. '
            'Once approved, you get full access to the app.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.login_rounded,
    title: 'Logging In',
    color: Color(0xFF0F2638),
    description:
        'Multiple secure ways to access your account — designed to be quick and safe.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Mobile + M-PIN',
        'Enter your registered 10-digit mobile number and 6-digit '
            'M-PIN to sign in.',
      ),
      _FeatureItem(
        'Biometric Login',
        'Use fingerprint or face ID for instant login without typing '
            'your M-PIN. Set this up during registration.',
      ),
      _FeatureItem(
        'Device Verification',
        'When logging in from a new device, an email OTP is sent '
            'to verify your identity and protect your account.',
      ),
      _FeatureItem(
        'Auto Logout',
        'For security, the app automatically logs you out after '
            '5 minutes of inactivity.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.dashboard_rounded,
    title: 'Dashboard',
    color: Color(0xFF7C3AED),
    description:
        'Your home screen with a quick overview of network activity and shortcuts to key features.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Member Statistics',
        'See total approved members and pending approval counts '
            'at a glance.',
      ),
      _FeatureItem(
        'Emergency Alerts',
        'View the most recent emergency alerts sent by members '
            'across the network.',
      ),
      _FeatureItem(
        'Help Feed Activity',
        'Quick preview of recent help requests posted by members.',
      ),
      _FeatureItem(
        'Quick Actions',
        'One-tap buttons to jump to Members, Help Feed, Donations, '
            'or Emergency Alerts.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.people_alt_rounded,
    title: 'Member Directory',
    color: Color(0xFF059669),
    description:
        'Find and connect with fellow members across the state. Search, filter, call, or message anyone in the network.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Search Members',
        'Search by name, mobile number, posting location, or district '
            'to quickly find who you need.',
      ),
      _FeatureItem(
        'Filter by Location',
        'Filter members by district, rank, department, or posting '
            'category to narrow your search.',
      ),
      _FeatureItem(
        'Nearby Members',
        'Enable proximity mode to find members within 100 km of your '
            'current location — perfect when transferred to a new area.',
      ),
      _FeatureItem(
        'Map View',
        'See nearby members on an interactive map with pins. Tap '
            'any member to get directions via Google Maps.',
      ),
      _FeatureItem(
        'Quick Contact',
        'Tap to call, WhatsApp, or share any member\'s contact '
            'details directly from their profile card.',
      ),
      _FeatureItem(
        'View Full Profile',
        'Open any member\'s complete profile including their posting '
            'details, home district, rank, and photos.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.feed_rounded,
    title: 'Help Feed',
    color: Color(0xFFEA580C),
    description:
        'A community board where members post requests for help — medical, financial, travel, or any other support.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Post a Help Request',
        'Create a new post describing what help you need. Choose a '
            'category (Emergency, Medical, Accident, Financial, Travel, Other) '
            'and add your message.',
      ),
      _FeatureItem(
        'Browse Help Posts',
        'View all recent help requests in a timeline. Each post shows '
            'the member name, category, message, and how long ago it was posted.',
      ),
      _FeatureItem(
        'Comment & Support',
        'Reply to any help post with advice, offers to help, or words '
            'of encouragement. Everyone can see the conversation.',
      ),
      _FeatureItem(
        'Contact the Requester',
        'Call or message the member who posted the request directly '
            'from the help feed.',
      ),
      _FeatureItem(
        'Post Expiry',
        'Help posts automatically expire after 7 days to keep the '
            'feed relevant and active.',
      ),
      _FeatureItem(
        'Delete Your Posts',
        'You can remove your own help posts when the issue is resolved '
            'or no longer needed.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.volunteer_activism_rounded,
    title: 'Donations',
    color: Color(0xFFDC2626),
    description:
        'Contribute to members in need or to the network fund. Transparent tracking with admin verification.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Make a Donation',
        'Send money via UPI to the network account. The app shows '
            'the UPI ID and QR code for easy payment.',
      ),
      _FeatureItem(
        'Submit Payment Proof',
        'After paying, upload a screenshot of the transaction and enter '
            'the reference number. Add a personal note if you like.',
      ),
      _FeatureItem(
        'Track Your Donations',
        'View your complete donation history with status — Pending, '
            'Verified, or Rejected — for full transparency.',
      ),
      _FeatureItem(
        'Admin Verification',
        'Admins review each donation screenshot and verify or reject '
            'it with a reason. This keeps records accurate.',
      ),
      _FeatureItem(
        'Donation Leaderboard',
        'See the top contributors in the network. A small recognition '
            'for those who give back the most.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.emergency_rounded,
    title: 'Emergency Alerts',
    color: Color(0xFFDC2626),
    description:
        'Send an SOS alert to ALL members instantly. Designed for real emergencies when you need immediate help.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Send SOS Alert',
        'With one tap, broadcast an emergency alert to every active '
            'member in the network. Your name, mobile, location, and message '
            'are included automatically.',
      ),
      _FeatureItem(
        'Custom Message',
        'Add a brief description of the emergency so members know '
            'exactly what kind of help is needed.',
      ),
      _FeatureItem(
        'Real-Time Notifications',
        'All members receive an instant push notification with alert '
            'details, even when the app is closed.',
      ),
      _FeatureItem(
        'Contact the Sender',
        'Tap to call or message the alert sender directly from the '
            'notification or alerts screen.',
      ),
      _FeatureItem(
        'Background Monitoring',
        'The app continuously monitors for new alerts in the background, '
            'so you never miss an emergency call for help.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.person_rounded,
    title: 'Profile & Updates',
    color: Color(0xFF0891B2),
    description:
        'Keep your information current — posting details, contact numbers, and profile photos.',
    features: <_FeatureItem>[
      _FeatureItem(
        'View Your Profile',
        'See your complete registered profile including photos, '
            'posting details, service profile, and home address.',
      ),
      _FeatureItem(
        'Update Posting Details',
        'When you get transferred, update your posting state, '
            'district, department, and exact location.',
      ),
      _FeatureItem(
        'Mandatory Refresh',
        'Every 6 months, the app asks you to confirm or update your '
            'posting details to keep records accurate.',
      ),
      _FeatureItem(
        'Update Contact Info',
        'Change your WhatsApp number, calling number, email, or '
            'other personal details anytime.',
      ),
      _FeatureItem(
        'Update Photos',
        'Upload a new selfie or ID card photo when needed.',
      ),
      _FeatureItem(
        'Live Location',
        'Share your real-time GPS coordinates so nearby members can '
            'find you easily using the proximity feature.',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.settings_rounded,
    title: 'Settings & Security',
    color: Color(0xFF64748B),
    description:
        'Manage your security preferences, language, notifications, and account options.',
    features: <_FeatureItem>[
      _FeatureItem(
        'Change M-PIN',
        'Update your 6-digit security PIN anytime from Settings.',
      ),
      _FeatureItem(
        'Language',
        'Switch between English and Hindi. The app remembers your '
            'preference.',
      ),
      _FeatureItem(
        'Notifications',
        'Enable or disable push notifications for alerts, help feed '
            'updates, and donation activity.',
      ),
      _FeatureItem(
        'Bug Report',
        'Found an issue? Use the Bug Report option to send details '
            'directly to the support team via WhatsApp.',
      ),
      _FeatureItem(
        'Terms & Privacy',
        'Read the complete terms of service and privacy policy '
            'at any time.',
      ),
      _FeatureItem(
        'Logout',
        'End your session securely. You will need to sign in again '
            'with your mobile and M-PIN.',
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Hindi content
// ---------------------------------------------------------------------------

const List<_SectionData> _sectionsHi = <_SectionData>[
  _SectionData(
    icon: Icons.person_add_alt_1_rounded,
    title: 'पंजीकरण और शुरुआत',
    color: Color(0xFF2563EB),
    description:
        'अपना खाता बनाएं और नेटवर्क से जुड़ें। 8-चरण पंजीकरण प्रवाह सुनिश्चित करता है कि हर सदस्य सत्यापित हो।',
    features: <_FeatureItem>[
      _FeatureItem(
        'खाता बनाएं',
        'अपना नाम, मोबाइल नंबर दर्ज करें और 6-अंकों की सुरक्षा M-PIN सेट करें। '
            'सेल्फी और वैकल्पिक रूप से आईडी कार्ड फोटो अपलोड करें।',
      ),
      _FeatureItem(
        'ईमेल सत्यापन',
        'अपने इनबॉक्स में भेजे गए OTP कोड से अपना व्यक्तिगत ईमेल पता सत्यापित करें।',
      ),
      _FeatureItem(
        'रेफरेंस सत्यापन',
        'एक मौजूदा सदस्य को अपने ईमेल OTP से आपका पंजीकरण सत्यापित करना होगा। '
            'यह नेटवर्क में विश्वास सुनिश्चित करता है।',
      ),
      _FeatureItem(
        'पोस्टिंग विवरण',
        'अपनी वर्तमान पोस्टिंग राज्य, जिला, विभाग, पोस्टिंग कैटेगरी, '
            'और GPS के साथ सटीक पोस्टिंग स्थान दर्ज करें।',
      ),
      _FeatureItem(
        'सेवा प्रोफाइल',
        'अपनी रैंक, बैच वर्ष, आधिकारिक नाम, लिंग, '
            'वैवाहिक स्थिति, और संपर्क नंबर (व्हाट्सएप और कॉलिंग) भरें।',
      ),
      _FeatureItem(
        'घर का विवरण',
        'अपना स्थायी घर का पता दर्ज करें — राज्य, जिला, '
            'तहसील, डाकघर, थाना, गाँव, और गली नंबर।',
      ),
      _FeatureItem(
        'एडमिन स्वीकृति',
        'जमा करने के बाद, आपकी प्रोफाइल एडमिन द्वारा समीक्षा की जाती है। '
            'स्वीकृति के बाद आपको ऐप का पूरा एक्सेस मिलता है।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.login_rounded,
    title: 'लॉगिन करना',
    color: Color(0xFF0F2638),
    description:
        'अपने खाते तक पहुंचने के कई सुरक्षित तरीके — तेज और सुरक्षित।',
    features: <_FeatureItem>[
      _FeatureItem(
        'मोबाइल + M-PIN',
        'साइन इन करने के लिए अपना पंजीकृत 10-अंकों का मोबाइल नंबर '
            'और 6-अंकों की M-PIN दर्ज करें।',
      ),
      _FeatureItem(
        'बायोमेट्रिक लॉगिन',
        'M-PIN टाइप किए बिना तुरंत लॉगिन के लिए फिंगरप्रिंट या '
            'फेस आईडी का उपयोग करें।',
      ),
      _FeatureItem(
        'डिवाइस सत्यापन',
        'नए डिवाइस से लॉगिन करते समय, आपकी पहचान सत्यापित करने '
            'के लिए एक ईमेल OTP भेजा जाता है।',
      ),
      _FeatureItem(
        'ऑटो लॉगआउट',
        'सुरक्षा के लिए, 5 मिनट की निष्क्रियता के बाद ऐप '
            'स्वचालित रूप से आपको लॉग आउट कर देता है।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.dashboard_rounded,
    title: 'डैशबोर्ड',
    color: Color(0xFF7C3AED),
    description:
        'नेटवर्क गतिविधि का त्वरित अवलोकन और मुख्य सुविधाओं के शॉर्टकट।',
    features: <_FeatureItem>[
      _FeatureItem(
        'सदस्य सांख्यिकी',
        'कुल स्वीकृत सदस्य और लंबित स्वीकृति की संख्या एक नज़र में देखें।',
      ),
      _FeatureItem(
        'आपातकालीन अलर्ट',
        'नेटवर्क में सदस्यों द्वारा भेजे गए हाल के आपातकालीन अलर्ट देखें।',
      ),
      _FeatureItem(
        'हेल्प फीड गतिविधि',
        'सदस्यों द्वारा पोस्ट किए गए हाल के सहायता अनुरोधों का पूर्वावलोकन।',
      ),
      _FeatureItem(
        'क्विक एक्शन',
        'सदस्य, हेल्प फीड, डोनेशन, या आपातकालीन अलर्ट पर जाने के लिए '
            'एक-टैप बटन।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.people_alt_rounded,
    title: 'सदस्य डायरेक्टरी',
    color: Color(0xFF059669),
    description:
        'राज्य भर में साथी सदस्यों को खोजें और उनसे जुड़ें। खोजें, फ़िल्टर करें, कॉल करें, या संदेश भेजें।',
    features: <_FeatureItem>[
      _FeatureItem(
        'सदस्य खोजें',
        'नाम, मोबाइल नंबर, पोस्टिंग स्थान, या जिले से खोजें।',
      ),
      _FeatureItem(
        'स्थान से फ़िल्टर',
        'जिला, रैंक, विभाग, या पोस्टिंग कैटेगरी से सदस्यों को फ़िल्टर करें।',
      ),
      _FeatureItem(
        'पास के सदस्य',
        'अपने वर्तमान स्थान से 100 किमी के भीतर सदस्य खोजने के लिए '
            'प्रॉक्सिमिटी मोड सक्षम करें।',
      ),
      _FeatureItem(
        'मैप व्यू',
        'पिन के साथ इंटरैक्टिव मैप पर पास के सदस्य देखें। '
            'किसी सदस्य पर टैप करें — कॉल, व्हाट्सएप, या दिशा-निर्देश विकल्प मिलेंगे।',
      ),
      _FeatureItem(
        'त्वरित संपर्क',
        'प्रोफाइल कार्ड से सीधे कॉल, व्हाट्सएप, या संपर्क विवरण साझा करें।',
      ),
      _FeatureItem(
        'पूरी प्रोफाइल देखें',
        'किसी भी सदस्य की पूरी प्रोफाइल खोलें — पोस्टिंग विवरण, '
            'गृह जिला, रैंक, और फोटो सहित।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.feed_rounded,
    title: 'हेल्प फीड',
    color: Color(0xFFEA580C),
    description:
        'सदस्यों का कम्युनिटी बोर्ड जहां सहायता अनुरोध पोस्ट किए जाते हैं — चिकित्सा, आर्थिक, यात्रा, या कोई अन्य सहायता।',
    features: <_FeatureItem>[
      _FeatureItem(
        'सहायता अनुरोध पोस्ट करें',
        'एक नई पोस्ट बनाएं जिसमें बताएं कि आपको किस मदद की जरूरत है। '
            'कैटेगरी चुनें (आपातकाल, चिकित्सा, दुर्घटना, आर्थिक, यात्रा, अन्य)।',
      ),
      _FeatureItem(
        'सहायता पोस्ट देखें',
        'टाइमलाइन में सभी हाल के सहायता अनुरोध देखें। प्रत्येक पोस्ट में '
            'सदस्य का नाम, कैटेगरी, संदेश, और समय दिखाई देता है।',
      ),
      _FeatureItem(
        'टिप्पणी और सहायता',
        'किसी भी सहायता पोस्ट पर सलाह, मदद की पेशकश, या प्रोत्साहन '
            'के शब्दों के साथ जवाब दें।',
      ),
      _FeatureItem(
        'अनुरोधकर्ता से संपर्क',
        'हेल्प फीड से सीधे अनुरोध पोस्ट करने वाले सदस्य को कॉल या संदेश भेजें।',
      ),
      _FeatureItem(
        'पोस्ट समाप्ति',
        'फीड को प्रासंगिक और सक्रिय रखने के लिए सहायता पोस्ट 7 दिन बाद '
            'स्वचालित रूप से समाप्त हो जाती हैं।',
      ),
      _FeatureItem(
        'अपनी पोस्ट हटाएं',
        'जब समस्या हल हो जाए या जरूरत न रहे तो आप अपनी सहायता पोस्ट हटा सकते हैं।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.volunteer_activism_rounded,
    title: 'डोनेशन',
    color: Color(0xFFDC2626),
    description:
        'जरूरतमंद सदस्यों या नेटवर्क फंड में योगदान दें। एडमिन सत्यापन के साथ पारदर्शी ट्रैकिंग।',
    features: <_FeatureItem>[
      _FeatureItem(
        'डोनेशन करें',
        'नेटवर्क खाते में UPI से पैसे भेजें। ऐप आसान भुगतान के लिए '
            'UPI ID और QR कोड दिखाता है।',
      ),
      _FeatureItem(
        'भुगतान प्रमाण जमा करें',
        'भुगतान करने के बाद, लेनदेन का स्क्रीनशॉट अपलोड करें और '
            'संदर्भ संख्या दर्ज करें।',
      ),
      _FeatureItem(
        'अपने डोनेशन ट्रैक करें',
        'अपना पूरा डोनेशन इतिहास स्थिति के साथ देखें — लंबित, '
            'सत्यापित, या अस्वीकृत।',
      ),
      _FeatureItem(
        'एडमिन सत्यापन',
        'एडमिन प्रत्येक डोनेशन स्क्रीनशॉट की समीक्षा करते हैं और '
            'कारण के साथ सत्यापित या अस्वीकार करते हैं।',
      ),
      _FeatureItem(
        'डोनेशन लीडरबोर्ड',
        'नेटवर्क में शीर्ष योगदानकर्ताओं को देखें।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.emergency_rounded,
    title: 'आपातकालीन अलर्ट',
    color: Color(0xFFDC2626),
    description:
        'सभी सदस्यों को तुरंत SOS अलर्ट भेजें। जब आपको तुरंत मदद चाहिए तब के लिए।',
    features: <_FeatureItem>[
      _FeatureItem(
        'SOS अलर्ट भेजें',
        'एक टैप से नेटवर्क के हर सक्रिय सदस्य को आपातकालीन अलर्ट भेजें। '
            'आपका नाम, मोबाइल, स्थान, और संदेश स्वचालित रूप से शामिल होता है।',
      ),
      _FeatureItem(
        'कस्टम संदेश',
        'आपातकाल का संक्षिप्त विवरण जोड़ें ताकि सदस्यों को पता चले '
            'कि किस तरह की मदद चाहिए।',
      ),
      _FeatureItem(
        'रियल-टाइम सूचनाएं',
        'सभी सदस्यों को अलर्ट विवरण के साथ तुरंत पुश नोटिफिकेशन मिलती है, '
            'ऐप बंद होने पर भी।',
      ),
      _FeatureItem(
        'भेजने वाले से संपर्क',
        'नोटिफिकेशन या अलर्ट स्क्रीन से सीधे अलर्ट भेजने वाले को '
            'कॉल या संदेश भेजें।',
      ),
      _FeatureItem(
        'बैकग्राउंड मॉनिटरिंग',
        'ऐप बैकग्राउंड में लगातार नए अलर्ट की निगरानी करता है, '
            'ताकि आप कभी कोई आपातकालीन कॉल न चूकें।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.person_rounded,
    title: 'प्रोफाइल और अपडेट',
    color: Color(0xFF0891B2),
    description:
        'अपनी जानकारी अपडेट रखें — पोस्टिंग विवरण, संपर्क नंबर, और प्रोफाइल फोटो।',
    features: <_FeatureItem>[
      _FeatureItem(
        'अपनी प्रोफाइल देखें',
        'अपनी पूरी पंजीकृत प्रोफाइल देखें — फोटो, पोस्टिंग विवरण, '
            'सेवा प्रोफाइल, और घर का पता सहित।',
      ),
      _FeatureItem(
        'पोस्टिंग विवरण अपडेट',
        'स्थानांतरण होने पर अपनी पोस्टिंग राज्य, जिला, विभाग, '
            'और सटीक स्थान अपडेट करें।',
      ),
      _FeatureItem(
        'अनिवार्य रिफ्रेश',
        'हर 6 महीने में, ऐप आपसे अपने पोस्टिंग विवरण की पुष्टि '
            'या अपडेट करने के लिए कहता है।',
      ),
      _FeatureItem(
        'संपर्क जानकारी अपडेट',
        'अपना व्हाट्सएप नंबर, कॉलिंग नंबर, ईमेल, या अन्य '
            'व्यक्तिगत विवरण कभी भी बदलें।',
      ),
      _FeatureItem(
        'फोटो अपडेट',
        'जरूरत पड़ने पर नई सेल्फी या आईडी कार्ड फोटो अपलोड करें।',
      ),
      _FeatureItem(
        'लाइव लोकेशन',
        'अपने रियल-टाइम GPS कोऑर्डिनेट्स साझा करें ताकि पास के सदस्य '
            'प्रॉक्सिमिटी फीचर से आपको आसानी से ढूंढ सकें।',
      ),
    ],
  ),
  _SectionData(
    icon: Icons.settings_rounded,
    title: 'सेटिंग्स और सुरक्षा',
    color: Color(0xFF64748B),
    description:
        'अपनी सुरक्षा प्राथमिकताएं, भाषा, सूचनाएं, और खाता विकल्प प्रबंधित करें।',
    features: <_FeatureItem>[
      _FeatureItem(
        'M-PIN बदलें',
        'सेटिंग्स से कभी भी अपनी 6-अंकों की सुरक्षा PIN अपडेट करें।',
      ),
      _FeatureItem(
        'भाषा',
        'अंग्रेजी और हिन्दी के बीच स्विच करें। ऐप आपकी प्राथमिकता याद रखता है।',
      ),
      _FeatureItem(
        'सूचनाएं',
        'अलर्ट, हेल्प फीड अपडेट, और डोनेशन गतिविधि के लिए '
            'पुश नोटिफिकेशन सक्षम या अक्षम करें।',
      ),
      _FeatureItem(
        'बग रिपोर्ट',
        'कोई समस्या मिली? बग रिपोर्ट विकल्प से सीधे व्हाट्सएप पर '
            'सपोर्ट टीम को विवरण भेजें।',
      ),
      _FeatureItem(
        'नियम और गोपनीयता',
        'सेवा की शर्तें और गोपनीयता नीति कभी भी पढ़ें।',
      ),
      _FeatureItem(
        'लॉगआउट',
        'अपना सत्र सुरक्षित रूप से समाप्त करें। आपको मोबाइल '
            'और M-PIN से फिर से साइन इन करना होगा।',
      ),
    ],
  ),
];
