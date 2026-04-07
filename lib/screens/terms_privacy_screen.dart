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
                    'These rules explain who can use the app, how registration works, and how member data is handled.',
              ),
              const SizedBox(height: 16),
              const _SectionHeading(
                title: 'Terms and Conditions',
                subtitle: 'Hindi and English wording kept side by side for clarity.',
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
                subtitle: 'How the app uses member information.',
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
                  'By continuing, you confirm that you understand these terms and agree to use the app responsibly.',
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
    hindi: 'यह App केवल उत्तर प्रदेश पुलिस कर्मचारियों के लिए है।',
    english: 'This app is intended only for Uttar Pradesh Police personnel.',
  ),
  _PolicyPoint(
    index: '2',
    hindi: 'इसका उद्देश्य बिना किसी भेदभाव के आपसी सहायता, जानकारी और सलाह देना है।',
    english: 'Its purpose is to provide mutual help, information, and guidance without discrimination.',
  ),
  _PolicyPoint(
    index: '3',
    hindi: 'Registration फॉर्म में सही और सत्य जानकारी दर्ज करें; गलत जानकारी मिलने पर Registration निरस्त किया जा सकता है।',
    english: 'Enter accurate and truthful information in the registration form; false details may result in cancellation of registration.',
  ),
  _PolicyPoint(
    index: '4',
    hindi: 'Registration के समय अपनी Posting Office/थाना की सही location अपडेट करें।',
    english: 'Update the correct location of your posting office or police station during registration.',
  ),
  _PolicyPoint(
    index: '5',
    hindi: 'अपनी Posting Details हर 6 माह में अपडेट करना अनिवार्य है।',
    english: 'Posting details must be updated every 6 months.',
  ),
  _PolicyPoint(
    index: '6',
    hindi: 'हर 30 दिन के भीतर App में लॉगिन करना आवश्यक है।',
    english: 'You must log in to the app at least once every 30 days.',
  ),
  _PolicyPoint(
    index: '7',
    hindi: 'App का उपयोग केवल गोपनीयता बनाए रखते हुए निजी सहायता के लिए करें।',
    english: 'Use the app only for private help while maintaining confidentiality.',
  ),
  _PolicyPoint(
    index: '8',
    hindi: 'मदद लेना अनिवार्य नहीं है, लेकिन अपेक्षित सहयोग सदैव रखा जाएगा।',
    english: 'Seeking help is optional, but respectful cooperation is expected.',
  ),
  _PolicyPoint(
    index: '9',
    hindi: 'यह App पूर्णतः गोपनीय है।',
    english: 'This app is confidential by design and use.',
  ),
  _PolicyPoint(
    index: '10',
    hindi: 'इस App से संबंधित कोई भी डेटा बाहरी व्यक्ति को साझा न करें।',
    english: 'Do not share any app-related data with unauthorized or external persons.',
  ),
  _PolicyPoint(
    index: '11',
    hindi: 'समय-समय पर लागू नियम और शर्तें प्रभावी रहेंगी।',
    english: 'Updated rules and conditions may apply from time to time.',
  ),
  _PolicyPoint(
    index: '12',
    hindi: 'अंतिम निर्णय Apne Saathi बोर्ड का होगा।',
    english: 'Final decisions rest with the Apne Saathi board.',
  ),
];

const List<_PolicyPoint> _privacy = <_PolicyPoint>[
  _PolicyPoint(
    index: '1',
    hindi: 'रजिस्ट्रेशन के दौरान केवल वही जानकारी एकत्र की जाएगी जो सदस्य सत्यापन और सेवा के लिए आवश्यक है।',
    english: 'Only the information required for member verification and service operation is collected during registration.',
  ),
  _PolicyPoint(
    index: '2',
    hindi: 'ईमेल, मोबाइल नंबर, फोटो, और लोकेशन डेटा सदस्य प्रबंधन, OTP सत्यापन, और सुरक्षा उद्देश्यों के लिए उपयोग होंगे।',
    english: 'Email, mobile number, photos, and location data are used for member management, OTP verification, and security purposes.',
  ),
  _PolicyPoint(
    index: '3',
    hindi: 'डेटा को अनधिकृत पहुंच से बचाने के लिए उचित तकनीकी और प्रशासनिक सुरक्षा अपनाई जाएगी।',
    english: 'Appropriate technical and administrative safeguards are used to protect data from unauthorized access.',
  ),
  _PolicyPoint(
    index: '4',
    hindi: 'सदस्य की जानकारी केवल App के अंदर आवश्यक सेवाओं और अनुमोदन प्रक्रियाओं के लिए साझा की जा सकती है।',
    english: 'Member details may be shared only within the app for required services and approval workflows.',
  ),
  _PolicyPoint(
    index: '5',
    hindi: 'आपकी जानकारी बाहरी विज्ञापन, विपणन, या गैर-प्राधिकृत उपयोग के लिए नहीं बेची जाएगी।',
    english: 'Your information will not be sold for external advertising, marketing, or unauthorized use.',
  ),
  _PolicyPoint(
    index: '6',
    hindi: 'सुरक्षा, ऑडिट, और सेवा सुधार के लिए सीमित लॉग या मेटाडेटा रखा जा सकता है।',
    english: 'Limited logs or metadata may be retained for security, audit, and service improvement.',
  ),
];
