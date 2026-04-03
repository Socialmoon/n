import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../models/member.dart';
import '../services/emergency_service.dart';

class EmergencyAlertScreen extends StatefulWidget {
  const EmergencyAlertScreen({
    required this.currentUser,
    required this.emergencyService,
    super.key,
  });

  final Member currentUser;
  final EmergencyService emergencyService;

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final isHindi = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'hi';
    _messageController.text =
        isHindi ? 'तुरंत सहायता आवश्यक' : 'Immediate assistance required';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(
          isHindi ? 'आपातकालीन अलर्ट' : 'Emergency Alert',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isHindi ? 'संदेश लिखें' : 'Write alert message',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: isHindi ? 'अलर्ट संदेश' : 'Alert message',
                        hintText: isHindi
                            ? 'उदाहरण: तत्काल सहायता आवश्यक...'
                            : 'Example: Immediate assistance needed at ...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHindi
                          ? 'आपका नाम और पोस्टिंग लोकेशन के साथ अलर्ट सभी सदस्यों को भेजा जाएगा।'
                          : 'Alert will be sent with your name and posting location to all members.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A6B74),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendAlert,
                icon: const Icon(Icons.sos_outlined),
                label: Text(
                  _sending
                      ? (isHindi ? 'भेजा जा रहा है...' : 'Sending...')
                      : (isHindi ? 'अलर्ट भेजें' : 'Send Alert'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAlert() async {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final message = _messageController.text.trim();

    setState(() {
      _sending = true;
    });

    final sent = await widget.emergencyService.triggerAlert(
      member: widget.currentUser,
      message: message.isEmpty
          ? (isHindi ? 'तुरंत सहायता आवश्यक' : 'Immediate assistance required')
          : message,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _sending = false;
    });

    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHindi
                ? 'क्लाउड पर अलर्ट भेजने में समस्या हुई। कृपया फिर प्रयास करें।'
                : 'Unable to send alert to cloud. Please retry.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHindi ? 'आपातकालीन अलर्ट भेज दिया गया।' : 'Emergency alert sent.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }
}
