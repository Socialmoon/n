import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/emergency_alert.dart';
import '../models/member.dart';

class SupabaseService {
  bool _initialized = false;
  static const Duration _initTimeout = Duration(seconds: 8);

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<void> initialize() async {
    if (!isConfigured || _initialized) {
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      ).timeout(_initTimeout);

      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) {
        // Use anonymous auth so RLS policies can rely on auth.uid().
        await client.auth.signInAnonymously().timeout(_initTimeout);
      }

      _initialized = true;
    } catch (error) {
      debugPrint('Supabase initialize failed, using local mode: $error');
      _initialized = false;
    }
  }

  Future<List<Member>> fetchMembers() async {
    if (!isConfigured || !_initialized) {
      return <Member>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('members')
          .select()
          .order('name') as List<dynamic>;
      return rows
          .map((row) => _memberFromRow(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchMembers failed: $error');
      return <Member>[];
    }
  }

  Future<void> upsertMember(Member member) async {
    if (!isConfigured || !_initialized) {
      return;
    }
    try {
      await Supabase.instance.client
          .from('members')
          .upsert(_memberToRow(member), onConflict: 'id');
    } catch (error) {
      debugPrint('Supabase upsertMember failed: $error');
    }
  }

  Future<List<EmergencyAlert>> fetchAlerts() async {
    if (!isConfigured || !_initialized) {
      return <EmergencyAlert>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('emergency_alerts')
          .select()
          .order('timestamp', ascending: false) as List<dynamic>;
      return rows
          .map((row) => _alertFromRow(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchAlerts failed: $error');
      return <EmergencyAlert>[];
    }
  }

  Future<void> insertAlert(EmergencyAlert alert) async {
    if (!isConfigured || !_initialized) {
      return;
    }
    try {
      await Supabase.instance.client.from('emergency_alerts').insert(
            _alertToRow(alert),
          );
    } catch (error) {
      debugPrint('Supabase insertAlert failed: $error');
    }
  }

  Map<String, dynamic> _memberToRow(Member member) {
    return <String, dynamic>{
      'id': member.id,
      'name': member.name,
      'mobile_number': member.mobileNumber,
      'user_id': member.userId,
      'password_hash': member.passwordHash,
      'mpin': member.mpin,
      'reference_mobile_number': member.referenceMobileNumber,
      'reference_member_name': member.referenceMemberName,
      'selfie_path': member.selfiePath,
      'id_card_photo_path': member.idCardPhotoPath,
      'home_district': member.homeDistrict,
      'posting_district': member.postingDistrict,
      'posting_location': member.postingLocation,
      'appointment_date': member.appointmentDate.toIso8601String(),
      'role': member.role,
      'last_updated': member.lastUpdated.toIso8601String(),
      'password_updated_at': member.passwordUpdatedAt.toIso8601String(),
      'is_admin': member.isAdmin,
    };
  }

  Member _memberFromRow(Map<String, dynamic> row) {
    return Member.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'name': row['name'] as String,
      'mobileNumber': row['mobile_number'] as String,
      'userId': row['user_id'] as String,
      'passwordHash': row['password_hash'] as String,
      'mpin': row['mpin'] as String,
      'referenceMobileNumber':
          (row['reference_mobile_number'] as String?) ?? '',
      'referenceMemberName': row['reference_member_name'] as String?,
      'selfiePath': row['selfie_path'] as String?,
        'idCardPhotoPath': row['id_card_photo_path'] as String?,
      'homeDistrict': row['home_district'] as String,
      'postingDistrict': row['posting_district'] as String,
      'postingLocation': row['posting_location'] as String,
      'appointmentDate': row['appointment_date'] as String,
      'role': row['role'] as String,
      'lastUpdated': row['last_updated'] as String,
      'passwordUpdatedAt': row['password_updated_at'] as String,
      'isAdmin': row['is_admin'] as bool? ?? false,
    });
  }

  Map<String, dynamic> _alertToRow(EmergencyAlert alert) {
    return <String, dynamic>{
      'id': alert.id,
      'member_id': alert.memberId,
      'member_name': alert.memberName,
      'timestamp': alert.timestamp.toIso8601String(),
      'message': alert.message,
      'location': alert.location,
    };
  }

  EmergencyAlert _alertFromRow(Map<String, dynamic> row) {
    return EmergencyAlert.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'memberId': row['member_id'] as String,
      'memberName': row['member_name'] as String,
      'timestamp': row['timestamp'] as String,
      'message': row['message'] as String,
      'location': row['location'] as String,
    });
  }
}