import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    onTap: () => _openRouteToMember(item),
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
              ? 'पिन पर टैप करें, उसी सदस्य का रूट खुलेगा।'
              : 'Tap any pin to open route only for that member.',
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
    final selfieUrl = member.selfiePath?.trim() ?? '';
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
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
                    backgroundColor: const Color(0xFFE8F0F5),
                    child: Text(
                      initial,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : Image.network(
                    selfieUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      backgroundColor: const Color(0xFFE8F0F5),
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
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.transparent, width: 6),
              right: BorderSide(color: Colors.transparent, width: 6),
              top: BorderSide(color: Color(0xFF1E88E5), width: 10),
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
