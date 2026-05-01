import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/cdn_config.dart';
import '../models/member.dart';

class RadiusMembersMapScreen extends StatelessWidget {
  const RadiusMembersMapScreen({
    required this.origin,
    required this.members,
    super.key,
  });

  final RadiusMapPoint origin;
  final List<RadiusMapPoint> members;

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'रेडियस मैप' : 'Radius Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _initialCenter(),
          initialZoom: _initialZoom(),
          maxZoom: 18,
          minZoom: 3,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'apne_saathi_app',
          ),
          MarkerLayer(
            markers: <Marker>[
              Marker(
                width: 50,
                height: 50,
                point: LatLng(origin.latitude, origin.longitude),
                child: _currentLocationPin(),
              ),
              ...members.map((item) {
                return Marker(
                  width: 70,
                  height: 84,
                  point: LatLng(item.latitude, item.longitude),
                  child: GestureDetector(
                    onTap: () => _showMemberActions(context, item),
                    child: _memberPin(item.member),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F7FA),
          border: Border(top: BorderSide(color: Color(0xFFD6E0E7))),
        ),
        child: Text(
          isHindi
              ? 'पिन पर टैप करें — कॉल, व्हाट्सएप या रूट का विकल्प मिलेगा।'
              : 'Tap any pin for Call, WhatsApp, or Direction options.',
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  LatLng _initialCenter() {
    if (members.isEmpty) {
      return LatLng(origin.latitude, origin.longitude);
    }

    final latSum = members.fold<double>(
      origin.latitude,
      (sum, item) => sum + item.latitude,
    );
    final lngSum = members.fold<double>(
      origin.longitude,
      (sum, item) => sum + item.longitude,
    );
    final total = members.length + 1;
    return LatLng(latSum / total, lngSum / total);
  }

  double _initialZoom() {
    if (members.length <= 2) {
      return 11;
    }
    if (members.length <= 8) {
      return 10;
    }
    return 9;
  }

  Future<void> _openRouteToMember(RadiusMapPoint point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${point.latitude},${point.longitude}&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showMemberActions(BuildContext context, RadiusMapPoint point) {
    final member = point.member;
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final selfieUrl = member.selfieUrl;
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFE8F0F5),
                      backgroundImage: selfieUrl.isNotEmpty
                          ? CachedNetworkImageProvider(
                              selfieUrl,
                              headers: CdnConfig.headersFor(selfieUrl),
                            )
                          : null,
                      child: selfieUrl.isEmpty
                          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18))
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.postingLocation,
                            style: const TextStyle(color: Color(0xFF5A6B74), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _actionButton(
                        icon: Icons.call_outlined,
                        label: isHindi ? 'कॉल' : 'Call',
                        color: const Color(0xFF1F7A3A),
                        bgColor: const Color(0xFFEAF7EE),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openPhone(member.mobileNumber);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.chat_outlined,
                        label: isHindi ? 'व्हाट्सएप' : 'WhatsApp',
                        color: const Color(0xFF25D366),
                        bgColor: const Color(0xFFE7FBF0),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openWhatsApp(member.whatsappNumber ?? member.mobileNumber);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.directions_outlined,
                        label: isHindi ? 'रूट' : 'Direction',
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openRouteToMember(point);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPhone(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String mobile) async {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return;
    }
    final normalized = digits.length > 10 ? digits : '91$digits';
    final uri = Uri.parse('https://wa.me/$normalized');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _currentLocationPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _memberPin(Member member) {
    final selfieUrl = member.selfieUrl;
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();
    const inRangeAccent = Color(0xFF198754);
    const inRangeBackground = Color(0xFFEAF7EF);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: inRangeBackground,
            shape: BoxShape.circle,
            border: Border.all(color: inRangeAccent, width: 2),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: selfieUrl.isEmpty
                ? CircleAvatar(
                    backgroundColor: inRangeBackground,
                    child: Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: selfieUrl,
                    httpHeaders: CdnConfig.headersFor(selfieUrl),
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => CircleAvatar(
                      backgroundColor: inRangeBackground,
                      child: Text(
                        initial,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
          ),
        ),
        Container(
          width: 0,
          height: 0,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(color: Colors.transparent, width: 6),
              right: BorderSide(color: Colors.transparent, width: 6),
              top: BorderSide(color: inRangeAccent, width: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class RadiusMapPoint {
  const RadiusMapPoint({
    required this.member,
    required this.latitude,
    required this.longitude,
  });

  final Member member;
  final double latitude;
  final double longitude;
}
