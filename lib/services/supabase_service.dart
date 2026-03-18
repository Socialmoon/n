import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/donation_entry.dart';
import '../models/emergency_alert.dart';
import '../models/help_comment.dart';
import '../models/help_post.dart';
import '../models/member.dart';

class SupabaseService {
  bool _initialized = false;
  static const Duration _initTimeout = Duration(seconds: 20);

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<void> initialize() async {
    if (!isConfigured || _initialized) {
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          // This app does not use Supabase email/magic-link callback flows.
          // Disable URI session detection to avoid web callback-code errors.
          detectSessionInUri: false,
        ),
      ).timeout(_initTimeout);

      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) {
        // Best-effort anonymous auth.
        // If it fails, keep Supabase initialized and continue with anon role access.
        try {
          await client.auth.signInAnonymously().timeout(_initTimeout);
        } catch (error) {
          debugPrint('Supabase anonymous sign-in failed, continuing as anon role: $error');
        }
      }

      _initialized = true;
    } catch (error) {
      debugPrint('Supabase initialize failed, using local mode: $error');
      _initialized = false;
    }
  }

  Future<List<Member>> fetchMembers() async {
    if (!isConfigured) {
      return <Member>[];
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return <Member>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('members')
          .select()
          .order('name') as List<dynamic>;
      final members = <Member>[];
      for (final row in rows) {
        final member = _tryMemberFromRow(row as Map<String, dynamic>);
        if (member != null) {
          members.add(member);
        }
      }
      return members;
    } catch (error) {
      debugPrint('Supabase fetchMembers failed: $error');
      return <Member>[];
    }
  }

  Future<Member?> fetchMemberByMobile(String mobileNumber) async {
    if (!isConfigured) {
      return null;
    }
    if (!_initialized) {
      await initialize();
    }
    final mobileCandidates = _mobileCandidates(mobileNumber);
    if (mobileCandidates.isEmpty) {
      return null;
    }

    if (_initialized) {
      try {
        for (final candidate in mobileCandidates) {
          final rows = await Supabase.instance.client
              .from('members')
              .select()
              .eq('mobile_number', candidate)
              .limit(1) as List<dynamic>;
          if (rows.isEmpty) {
            continue;
          }
          final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
          if (member != null) {
            return member;
          }
        }
      } catch (error) {
        debugPrint('Supabase SDK fetchMemberByMobile failed: $error');
      }
    }

    // SDK fallback: direct REST query with anon key so login can still resolve
    // seeded members even when client initialization/auth has transient issues.
    try {
      for (final candidate in mobileCandidates) {
        final uri = Uri.parse(
          '${SupabaseConfig.url}/rest/v1/members?select=*&mobile_number=eq.$candidate&limit=1',
        );
        final response = await http.get(
          uri,
          headers: <String, String>{
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint('Supabase REST fallback failed for $candidate: HTTP ${response.statusCode}');
          continue;
        }
        final rows = (response.body.isEmpty ? <dynamic>[] : (jsonDecode(response.body) as List<dynamic>));
        if (rows.isEmpty) {
          continue;
        }
        final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
        if (member != null) {
          return member;
        }
      }
      return null;
    } catch (error) {
      debugPrint('Supabase REST fallback fetchMemberByMobile failed: $error');
      return null;
    }
  }

  Future<void> upsertMember(Member member) async {
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
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
    if (!isConfigured) {
      return <EmergencyAlert>[];
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
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
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
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

  Future<List<HelpPost>> fetchHelpPosts() async {
    if (!isConfigured) {
      return <HelpPost>[];
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return <HelpPost>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('help_posts')
          .select()
          .order('created_at', ascending: false) as List<dynamic>;
      return rows
          .map((row) => _helpPostFromRow(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchHelpPosts failed: $error');
      return <HelpPost>[];
    }
  }

  Future<void> insertHelpPost(HelpPost post) async {
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return;
    }
    try {
      await Supabase.instance.client.from('help_posts').insert(
            _helpPostToRow(post),
          );
    } catch (error) {
      debugPrint('Supabase insertHelpPost failed: $error');
    }
  }

  Future<void> deleteHelpPost(String postId) async {
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return;
    }
    try {
      await Supabase.instance.client.from('help_posts').delete().eq('id', postId);
    } catch (error) {
      debugPrint('Supabase deleteHelpPost failed: $error');
    }
  }

  Future<List<HelpComment>> fetchHelpComments() async {
    if (!isConfigured) {
      return <HelpComment>[];
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return <HelpComment>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('help_post_comments')
          .select()
          .order('created_at', ascending: false) as List<dynamic>;
      return rows
          .map((row) => _helpCommentFromRow(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchHelpComments failed: $error');
      return <HelpComment>[];
    }
  }

  Future<void> insertHelpComment(HelpComment comment) async {
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return;
    }
    try {
      await Supabase.instance.client.from('help_post_comments').insert(
            _helpCommentToRow(comment),
          );
    } catch (error) {
      debugPrint('Supabase insertHelpComment failed: $error');
    }
  }

  Future<List<DonationEntry>> fetchDonations() async {
    if (!isConfigured) {
      return <DonationEntry>[];
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return <DonationEntry>[];
    }
    try {
      final rows = await Supabase.instance.client
          .from('donations')
          .select()
          .order('created_at', ascending: false) as List<dynamic>;
      return rows
          .map((row) => _donationFromRow(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Supabase fetchDonations failed: $error');
      return <DonationEntry>[];
    }
  }

  Future<void> insertDonation(DonationEntry entry) async {
    if (!isConfigured) {
      return;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return;
    }
    try {
      await Supabase.instance.client.from('donations').insert(
            _donationToRow(entry),
          );
    } catch (error) {
      debugPrint('Supabase insertDonation failed: $error');
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

  Member? _tryMemberFromRow(Map<String, dynamic> row) {
    try {
      return _memberFromRow(row);
    } catch (error) {
      final id = row['id'];
      debugPrint('Skipping malformed member row${id != null ? ' ($id)' : ''}: $error');
      return null;
    }
  }

  List<String> _mobileCandidates(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const <String>[];
    }

    final lastTen = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final candidates = <String>[];

    void add(String item) {
      if (item.isEmpty || candidates.contains(item)) {
        return;
      }
      candidates.add(item);
    }

    add(value.trim());
    add(digits);
    add(lastTen);
    if (lastTen.length == 10) {
      add('91$lastTen');
      add('+91$lastTen');
      add('0$lastTen');
    }

    return candidates;
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

  Map<String, dynamic> _helpPostToRow(HelpPost post) {
    return <String, dynamic>{
      'id': post.id,
      'member_id': post.memberId,
      'member_name': post.memberName,
      'member_mobile': post.memberMobile,
      'category': post.category,
      'message': post.message,
      'location': post.location,
      'requested_amount': post.requestedAmount,
      'created_at': post.createdAt.toIso8601String(),
    };
  }

  HelpPost _helpPostFromRow(Map<String, dynamic> row) {
    return HelpPost.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'memberId': row['member_id'] as String,
      'memberName': row['member_name'] as String,
      'memberMobile': row['member_mobile'] as String,
      'category': row['category'] as String,
      'message': row['message'] as String,
      'location': row['location'] as String,
      'requestedAmount': (row['requested_amount'] as num?)?.toDouble(),
      'createdAt': row['created_at'] as String,
    });
  }

  Map<String, dynamic> _helpCommentToRow(HelpComment comment) {
    return <String, dynamic>{
      'id': comment.id,
      'post_id': comment.postId,
      'member_id': comment.memberId,
      'member_name': comment.memberName,
      'message': comment.message,
      'created_at': comment.createdAt.toIso8601String(),
    };
  }

  HelpComment _helpCommentFromRow(Map<String, dynamic> row) {
    return HelpComment.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'postId': row['post_id'] as String,
      'memberId': row['member_id'] as String,
      'memberName': row['member_name'] as String,
      'message': row['message'] as String,
      'createdAt': row['created_at'] as String,
    });
  }

  Map<String, dynamic> _donationToRow(DonationEntry entry) {
    return <String, dynamic>{
      'id': entry.id,
      'member_id': entry.memberId,
      'member_name': entry.memberName,
      'member_mobile': entry.memberMobile,
      'amount': entry.amount,
      'upi_id': entry.upiId,
      'status': entry.status,
      'transaction_ref': entry.transactionRef,
      'note': entry.note,
      'screenshot_path': entry.screenshotPath,
      'created_at': entry.createdAt.toIso8601String(),
    };
  }

  DonationEntry _donationFromRow(Map<String, dynamic> row) {
    return DonationEntry.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'memberId': row['member_id'] as String,
      'memberName': row['member_name'] as String,
      'memberMobile': row['member_mobile'] as String,
      'amount': (row['amount'] as num).toDouble(),
      'upiId': row['upi_id'] as String,
      'status': row['status'] as String,
      'transactionRef': row['transaction_ref'] as String?,
      'note': row['note'] as String?,
      'screenshotPath': row['screenshot_path'] as String?,
      'createdAt': row['created_at'] as String,
    });
  }
}