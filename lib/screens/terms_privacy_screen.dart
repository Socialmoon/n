import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  static const Color _ink = Color(0xFF0F2A33);
  static const Color _accent = Color(0xFFB47A2F);
  static const Color _surface = Color(0xFFF7F9FB);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFDCE5EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF6F1E6), Color(0xFFF2F7FA)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _HeroCard(
                title: 'Terms, Privacy and Use',
                subtitle:
                    'Please read these terms carefully before using the application. They explain eligibility, responsible use, and data handling practices.',
              ),
              const SizedBox(height: 16),
              const _SectionHeading(
                title: 'Terms and Conditions',
                subtitle:
                    'Binding rules for registration, account use, and conduct.',
              ),
              const SizedBox(height: 12),
              ..._terms.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PointCard(
                    index: item.index,
                    hindi: item.hindi,
                    english: item.english,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _SectionHeading(
                title: 'Privacy Policy',
                subtitle:
                    'How personal data is collected, used, protected, and retained.',
              ),
              const SizedBox(height: 12),
              ..._privacy.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PointCard(
                    index: item.index,
                    hindi: item.hindi,
                    english: item.english,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F3E6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7D8B7)),
                ),
                child: const Text(
                  'By proceeding, you acknowledge that you have read and accepted these Terms and Privacy Policy.',
                  style: TextStyle(height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: TermsPrivacyScreen._ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: const Color(0xFF5B6972),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F2A33), Color(0xFF173C49)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.gavel_outlined, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.index,
    required this.hindi,
    required this.english,
  });

  final String index;
  final String hindi;
  final String english;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TermsPrivacyScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TermsPrivacyScreen._border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E2C9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              index,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: TermsPrivacyScreen._ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hindi,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: TermsPrivacyScreen._ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  english,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    height: 1.55,
                    color: const Color(0xFF5B6972),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyPoint {
  const _PolicyPoint({
    required this.index,
    required this.hindi,
    required this.english,
  });

  final String index;
  final String hindi;
  final String english;
}

const List<_PolicyPoint> _terms = <_PolicyPoint>[
  _PolicyPoint(
    index: '1',
    hindi:
        'यह ऐप केवल पात्र और सत्यापित उत्तर प्रदेश पुलिस कर्मियों के उपयोग के लिए है।',
    english:
        'This application is intended solely for eligible and verified Uttar Pradesh Police personnel.',
  ),
  _PolicyPoint(
    index: '2',
    hindi:
        'पंजीकरण के समय दी गई सभी जानकारी सही, पूर्ण और अद्यतन होना उपयोगकर्ता की जिम्मेदारी है।',
    english:
        'You are responsible for ensuring that all registration details are accurate, complete, and up to date.',
  ),
  _PolicyPoint(
    index: '3',
    hindi:
        'गलत, भ्रामक या जाली सूचना मिलने पर खाता निलंबित या निरस्त किया जा सकता है।',
    english:
        'Any false, misleading, or forged information may lead to suspension or cancellation of your account.',
  ),
  _PolicyPoint(
    index: '4',
    hindi:
        'उपयोगकर्ता अपने लॉगिन क्रेडेंशियल, एम-पिन और डिवाइस एक्सेस की गोपनीयता बनाए रखेगा।',
    english:
        'You must keep your login credentials, M-PIN, and device access confidential at all times.',
  ),
  _PolicyPoint(
    index: '5',
    hindi:
        'पोस्टिंग, विभागीय और संपर्क विवरण में परिवर्तन होने पर उसे यथाशीघ्र अपडेट करना अनिवार्य है।',
    english:
        'Posting, departmental, and contact details must be updated promptly whenever changes occur.',
  ),
  _PolicyPoint(
    index: '6',
    hindi:
        'ऐप का उपयोग केवल वैध सेवा-संबंधी सहायता, संचार और प्रशासनिक उद्देश्यों के लिए किया जाएगा।',
    english:
        'The app may be used only for legitimate service-related assistance, communication, and administrative purposes.',
  ),
  _PolicyPoint(
    index: '7',
    hindi:
        'किसी भी सदस्य की जानकारी, फोटो या स्थान डेटा को बिना अनुमति बाहरी व्यक्तियों के साथ साझा करना प्रतिबंधित है।',
    english:
        'Sharing any member information, photos, or location data with unauthorized external persons is strictly prohibited.',
  ),
  _PolicyPoint(
    index: '8',
    hindi: 'ऐप का उपयोग कानून, विभागीय नियमों और अनुशासन के अनुरूप होना चाहिए।',
    english:
        'Use of the app must comply with applicable law, departmental rules, and professional discipline.',
  ),
  _PolicyPoint(
    index: '9',
    hindi:
        'सेवा की उपलब्धता, प्रदर्शन या त्रुटि-मुक्त संचालन के संबंध में यथासंभव प्रयास किए जाएंगे, पर पूर्ण गारंटी नहीं दी जाती।',
    english:
        'Reasonable efforts are made to maintain availability and performance; however, uninterrupted or error-free operation is not guaranteed.',
  ),
  _PolicyPoint(
    index: '10',
    hindi:
        'प्रशासन आवश्यकता अनुसार खाते की समीक्षा, सीमित या निरस्त करने का अधिकार सुरक्षित रखता है।',
    english:
        'The administration reserves the right to review, restrict, or terminate access where required.',
  ),
  _PolicyPoint(
    index: '11',
    hindi:
        'नियम एवं शर्तें समय-समय पर संशोधित की जा सकती हैं; संशोधित संस्करण प्रकाशित होते ही प्रभावी होगा।',
    english:
        'These Terms may be updated from time to time, and revised versions become effective upon publication.',
  ),
  _PolicyPoint(
    index: '12',
    hindi:
        'ऐप का निरंतर उपयोग इन शर्तों और गोपनीयता नीति की स्वीकृति माना जाएगा।',
    english:
        'Continued use of the app constitutes acceptance of these Terms and the Privacy Policy.',
  ),
];

const List<_PolicyPoint> _privacy = <_PolicyPoint>[
  _PolicyPoint(
    index: '1',
    hindi:
        'हम केवल वही व्यक्तिगत जानकारी एकत्र करते हैं जो सदस्य सत्यापन, सुरक्षा और सेवा संचालन के लिए आवश्यक है।',
    english:
        'We collect only the personal information necessary for member verification, security, and service operation.',
  ),
  _PolicyPoint(
    index: '2',
    hindi:
        'संग्रहित डेटा में नाम, मोबाइल, ईमेल, प्रोफाइल/दस्तावेज फोटो, पोस्टिंग विवरण और आवश्यक स्थान जानकारी शामिल हो सकती है।',
    english:
        'Collected data may include name, mobile number, email, profile/document images, posting details, and required location information.',
  ),
  _PolicyPoint(
    index: '3',
    hindi:
        'यह जानकारी OTP सत्यापन, खाता सुरक्षा, प्रशासनिक अनुमोदन, सहायता सुविधाओं और सिस्टम अखंडता के लिए उपयोग की जाती है।',
    english:
        'This information is used for OTP verification, account security, administrative approvals, support features, and system integrity.',
  ),
  _PolicyPoint(
    index: '4',
    hindi:
        'डेटा तक पहुंच केवल अधिकृत उपयोगकर्ताओं/प्रशासकों तक सीमित रखी जाती है और आवश्यकता-आधारित सिद्धांत पर नियंत्रित होती है।',
    english:
        'Access to data is restricted to authorized users/administrators and controlled on a need-to-know basis.',
  ),
  _PolicyPoint(
    index: '5',
    hindi:
        'हम आपकी व्यक्तिगत जानकारी को बाहरी विज्ञापन या अनधिकृत व्यावसायिक उद्देश्यों के लिए नहीं बेचते।',
    english:
        'We do not sell your personal data for external advertising or unauthorized commercial purposes.',
  ),
  _PolicyPoint(
    index: '6',
    hindi:
        'सुरक्षा, ऑडिट, धोखाधड़ी-निरोध, और सेवा सुधार के लिए सीमित तकनीकी लॉग/मेटाडेटा सुरक्षित रखा जा सकता है।',
    english:
        'Limited technical logs/metadata may be retained for security, audit, fraud prevention, and service improvement.',
  ),
  _PolicyPoint(
    index: '7',
    hindi:
        'कानूनी दायित्व, सुरक्षा जोखिम, या विभागीय अनुरोध की स्थिति में लागू कानून के अनुसार आवश्यक प्रकटीकरण किया जा सकता है।',
    english:
        'Where required by law, security risk, or departmental request, necessary disclosures may be made in accordance with applicable law.',
  ),
  _PolicyPoint(
    index: '8',
    hindi:
        'डेटा संरक्षण से जुड़े प्रश्नों या संशोधन अनुरोधों के लिए उपयोगकर्ता प्रशासनिक सहायता चैनल के माध्यम से संपर्क कर सकता है।',
    english:
        'For data protection questions or correction requests, users may contact the administrative support channel.',
  ),
];
