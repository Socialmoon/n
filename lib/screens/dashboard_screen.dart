import 'package:flutter/material.dart';

import '../models/emergency_alert.dart';
import '../models/member.dart';
import '../services/emergency_service.dart';
import '../services/member_repository.dart';
import '../widgets/member_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.currentUser,
    required this.repository,
    required this.emergencyService,
    required this.onLogout,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final EmergencyService emergencyService;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _queryController = TextEditingController();
  final _districtController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.repository.search(
      query: _queryController.text,
      districtFilter: _districtController.text,
    );
    final visibleMembers = members.where((member) => member.id != widget.currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Directory'),
        actions: <Widget>[
          IconButton(
            onPressed: _triggerAlert,
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Emergency alert',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF123C56), Color(0xFF266D7A)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, ${widget.currentUser.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.currentUser.role} • ${widget.currentUser.postingLocation}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (widget.currentUser.referenceMemberName != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Referred by ${widget.currentUser.referenceMemberName}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: 'Search by name, role, or posting location',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'Filter by posting district',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text(
            'Visible member data excludes home district. Admin accounts can see it in the cards below.',
          ),
          const SizedBox(height: 12),
          if (visibleMembers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No members match the current filters.'),
              ),
            ),
          ...visibleMembers.map(
            (member) => MemberCard(
              member: member,
              showAdminFields: widget.currentUser.isAdmin,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent emergency alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.emergencyService.alerts.take(5).map(_buildAlertCard),
          if (widget.emergencyService.alerts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No emergency alerts have been triggered yet.'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerAlert,
        icon: const Icon(Icons.sos_outlined),
        label: const Text('Emergency'),
      ),
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(alert.message),
        subtitle: Text(
          '${alert.memberName} • ${alert.location} • ${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year} ${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Future<void> _triggerAlert() async {
    final controller = TextEditingController(text: 'Immediate assistance required');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trigger emergency alert'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Alert message'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send alert'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    await widget.emergencyService.triggerAlert(
      member: widget.currentUser,
      message: controller.text.trim().isEmpty
          ? 'Immediate assistance required'
          : controller.text.trim(),
    );
    controller.dispose();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency alert triggered.')),
    );
  }
}