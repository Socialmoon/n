import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cdn_config.dart';
import '../core/supabase_config.dart';
import '../models/donation_entry.dart';
import '../models/emergency_alert.dart';
import '../models/help_comment.dart';
import '../models/help_post.dart';
import '../models/member.dart';

class SupabaseService {
  bool _initialized = false;
  String? _lastWriteError;
  String? _lastUploadError;
  bool? _mediaIsPrivate;
  static const Duration _initTimeout = Duration(seconds: 20);
  static const String _mediaBucket = 'app-media';
  static final Random _random = Random.secure();

  bool get isConfigured => SupabaseConfig.isConfigured;
  String get supabaseUrl => SupabaseConfig.url;
  String? get lastWriteError => _lastWriteError;
  String? get lastUploadError => _lastUploadError;

  Future<bool> _ensureInitialized() async {
    if (!isConfigured) {
      return false;
    }
    if (!_initialized) {
      await initialize();
    }
    return _initialized;
  }

  Future<bool> _ensureWriteSession() async {
    final initialized = await _ensureInitialized();
    if (!initialized) {
      return false;
    }
    return true;
  }

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

      _initialized = true;
    } catch (error) {
      debugPrint('Supabase initialize failed, using local mode: $error');
      _initialized = false;
    }
  }

  Future<bool> _isPrivateMediaEnabled() async {
    if (_mediaIsPrivate != null) {
      return _mediaIsPrivate!;
    }
    final value = await fetchAppSetting(key: 'app_media_is_private');
    _mediaIsPrivate = value?.toLowerCase() == 'true';
    return _mediaIsPrivate!;
  }

  String? storagePathFromMediaValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      if (trimmed.startsWith('app-media/')) {
        return trimmed.substring('app-media/'.length);
      }
      return trimmed;
    }

    final publicPrefix = '/storage/v1/object/public/$_mediaBucket/';
    final signedPrefix = '/storage/v1/object/sign/$_mediaBucket/';
    if (uri.path.startsWith(publicPrefix)) {
      return uri.path.substring(publicPrefix.length);
    }
    if (uri.path.startsWith(signedPrefix)) {
      final path = uri.path.substring(signedPrefix.length);
      return path.split('?').first;
    }

    return trimmed;
  }

  Future<String?> resolveMediaUrl(String? value) async {
    final storagePath = storagePathFromMediaValue(value);
    if (storagePath == null || storagePath.isEmpty) {
      return null;
    }

    if (await _isPrivateMediaEnabled()) {
      try {
        return await Supabase.instance.client.storage
            .from(_mediaBucket)
            .createSignedUrl(storagePath, 60 * 60 * 24);
      } catch (error) {
        debugPrint('Supabase createSignedUrl failed: $error');
        return null;
      }
    }

    final publicUrl = Supabase.instance.client.storage
        .from(_mediaBucket)
        .getPublicUrl(storagePath);
    return CdnConfig.rewrite(publicUrl);
  }

  Future<Member> _hydrateMemberMedia(Member member) async {
    final selfieUrl = await resolveMediaUrl(member.selfiePath);
    final idCardUrl = await resolveMediaUrl(member.idCardPhotoPath);
    return member.copyWith(
      selfiePath: selfieUrl,
      idCardPhotoPath: idCardUrl,
    );
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
          members.add(await _hydrateMemberMedia(member));
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

    Member? latestMatch;

    if (_initialized) {
      try {
        for (final candidate in mobileCandidates) {
          final rows = await Supabase.instance.client
              .from('members')
              .select()
              .eq('mobile_number', candidate)
              .order('last_updated', ascending: false)
              .limit(1) as List<dynamic>;
          if (rows.isEmpty) {
            continue;
          }
          final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
          if (member != null &&
              (latestMatch == null ||
                  member.lastUpdated.isAfter(latestMatch.lastUpdated))) {
            latestMatch = await _hydrateMemberMedia(member);
          }
        }
        if (latestMatch != null) {
          return latestMatch;
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
          '${SupabaseConfig.url}/rest/v1/members?select=*&mobile_number=eq.$candidate&order=last_updated.desc&limit=1',
        );
        final response = await http.get(
          uri,
          headers: <String, String>{
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
              'Supabase REST fallback failed for $candidate: HTTP ${response.statusCode}');
          continue;
        }
        final rows = (response.body.isEmpty
            ? <dynamic>[]
            : (jsonDecode(response.body) as List<dynamic>));
        if (rows.isEmpty) {
          continue;
        }
        final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
        if (member != null &&
            (latestMatch == null ||
                member.lastUpdated.isAfter(latestMatch.lastUpdated))) {
          latestMatch = await _hydrateMemberMedia(member);
        }
      }
      return latestMatch;
    } catch (error) {
      debugPrint('Supabase REST fallback fetchMemberByMobile failed: $error');
      return null;
    }
  }

  Future<Member?> fetchMemberByEmail(String email) async {
    if (!isConfigured) {
      return null;
    }
    if (!_initialized) {
      await initialize();
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    Member? latestMatch;

    if (_initialized) {
      try {
        final rows = await Supabase.instance.client
            .from('members')
            .select()
            .ilike('email', normalizedEmail)
            .order('last_updated', ascending: false)
            .limit(1) as List<dynamic>;
        if (rows.isNotEmpty) {
          final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
          if (member != null) {
            latestMatch = await _hydrateMemberMedia(member);
          }
        }
      } catch (error) {
        debugPrint('Supabase SDK fetchMemberByEmail failed: $error');
      }
    }

    if (latestMatch != null) {
      return latestMatch;
    }

    try {
      final encoded = Uri.encodeQueryComponent(normalizedEmail);
      final uri = Uri.parse(
        '${SupabaseConfig.url}/rest/v1/members?select=*&email=ilike.$encoded&order=last_updated.desc&limit=1',
      );
      final response = await http.get(
        uri,
        headers: <String, String>{
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Supabase REST fallback fetchMemberByEmail failed: HTTP ${response.statusCode}');
        return null;
      }
      final rows = (response.body.isEmpty
          ? <dynamic>[]
          : (jsonDecode(response.body) as List<dynamic>));
      if (rows.isEmpty) {
        return null;
      }
      final member = _tryMemberFromRow(rows.first as Map<String, dynamic>);
      return member == null ? null : await _hydrateMemberMedia(member);
    } catch (error) {
      debugPrint('Supabase REST fallback fetchMemberByEmail failed: $error');
      return null;
    }
  }

  Future<bool> upsertMember(Member member) async {
    _lastWriteError = null;
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastWriteError = 'Supabase client is not initialized.';
      return false;
    }
    // Best-effort anonymous session. Some projects still allow anon-role writes
    // without an authenticated session, so do not fail early on session absence.
    await _ensureWriteSession();

    final client = Supabase.instance.client;
    final strippedColumns = <String>{};
    final baseRow = _memberToRow(member);

    // Update-first avoids owner_id NOT NULL failures for existing members when
    // the current auth session is missing/expired during device-binding saves.
    final updateRow = Map<String, dynamic>.from(baseRow)..remove('owner_id');
    while (true) {
      try {
        final rows = await client
            .from('members')
            .update(updateRow)
            .eq('id', member.id)
            .select('id')
            .limit(1) as List<dynamic>;
        if (rows.isNotEmpty) {
          return true;
        }
        break;
      } on PostgrestException catch (error) {
        final missingColumn = _extractMissingColumnName(error.message);
        if (missingColumn != null && updateRow.containsKey(missingColumn)) {
          strippedColumns.add(missingColumn);
          updateRow.remove(missingColumn);
          continue;
        }
        debugPrint('Supabase upsertMember update-first attempt failed: $error');
        break;
      } catch (error) {
        debugPrint('Supabase upsertMember update-first attempt failed: $error');
        break;
      }
    }

    var currentUserId = _writeOwnerId();
    if (currentUserId.isEmpty) {
      _lastWriteError = 'Unable to create new member owner_id.';
      return false;
    }

    final insertRow = _memberToRow(
      member,
      ownerId: currentUserId,
      includeOwnerId: true,
    )..removeWhere((key, _) => strippedColumns.contains(key));

    while (true) {
      try {
        await client.from('members').insert(insertRow);
        return true;
      } on PostgrestException catch (error) {
        final missingColumn = _extractMissingColumnName(error.message);
        if (missingColumn != null && insertRow.containsKey(missingColumn)) {
          strippedColumns.add(missingColumn);
          insertRow.remove(missingColumn);
          continue;
        }

        if (error.code == '23505') {
          return _updateMemberWithSchemaFallback(
            client,
            memberId: member.id,
            row: _memberToRow(member),
            strippedColumns: strippedColumns,
          );
        }

        _lastWriteError = _compactError(error.message);
        debugPrint('Supabase upsertMember insert fallback failed: $error');
        return false;
      } catch (error) {
        _lastWriteError = _compactError(error.toString());
        debugPrint('Supabase upsertMember fallback failed: $error');
        return false;
      }
    }
  }

  Future<bool> _updateMemberWithSchemaFallback(
    SupabaseClient client, {
    required String memberId,
    required Map<String, dynamic> row,
    required Set<String> strippedColumns,
  }) async {
    final updateRow = Map<String, dynamic>.from(row)
      ..removeWhere((key, _) => strippedColumns.contains(key));

    while (true) {
      try {
        await client
            .from('members')
            .update(updateRow)
            .eq('id', memberId);
        return true;
      } on PostgrestException catch (error) {
        final missingColumn = _extractMissingColumnName(error.message);
        if (missingColumn != null && updateRow.containsKey(missingColumn)) {
          strippedColumns.add(missingColumn);
          updateRow.remove(missingColumn);
          continue;
        }
        _lastWriteError = _compactError(error.message);
        debugPrint('Supabase update member fallback failed: $error');
        return false;
      } catch (error) {
        _lastWriteError = _compactError(error.toString());
        debugPrint('Supabase update member fallback failed: $error');
        return false;
      }
    }
  }

  String? _extractMissingColumnName(String message) {
    final relationColumnMatch = RegExp(
      r'column\s+"([a-zA-Z0-9_]+)"\s+of\s+relation\s+"members"\s+does\s+not\s+exist',
      caseSensitive: false,
    ).firstMatch(message);
    if (relationColumnMatch != null) {
      return relationColumnMatch.group(1);
    }

    final schemaCacheMatch = RegExp(
      r"Could not find the '([a-zA-Z0-9_]+)' column of 'members'",
      caseSensitive: false,
    ).firstMatch(message);
    if (schemaCacheMatch != null) {
      return schemaCacheMatch.group(1);
    }

    return null;
  }

  String? _extractMissingColumnNameForTable({
    required String tableName,
    required String message,
  }) {
    final escapedTable = RegExp.escape(tableName);
    final relationColumnMatch = RegExp(
      'column\\s+"([a-zA-Z0-9_]+)"\\s+of\\s+relation\\s+"$escapedTable"\\s+does\\s+not\\s+exist',
      caseSensitive: false,
    ).firstMatch(message);
    if (relationColumnMatch != null) {
      return relationColumnMatch.group(1);
    }

    final schemaCacheMatch = RegExp(
      "Could not find the '([a-zA-Z0-9_]+)' column of '$escapedTable'",
      caseSensitive: false,
    ).firstMatch(message);
    if (schemaCacheMatch != null) {
      return schemaCacheMatch.group(1);
    }

    return null;
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
      List<dynamic> rows;
      try {
        rows = await Supabase.instance.client
            .from('emergency_alerts')
            .select()
            .order('created_at', ascending: false) as List<dynamic>;
      } catch (_) {
        rows = await Supabase.instance.client
            .from('emergency_alerts')
            .select()
            .order('timestamp', ascending: false) as List<dynamic>;
      }

        final alerts = rows
          .map((row) => _alertFromRow(row as Map<String, dynamic>))
          .toList();
        alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return alerts;
    } catch (error) {
      debugPrint('Supabase fetchAlerts failed: $error');
      return <EmergencyAlert>[];
    }
  }

  Future<EmergencyAlert?> insertAlert(EmergencyAlert alert) async {
    _lastWriteError = null;
    final initialized = await _ensureInitialized();
    if (!initialized) {
      _lastWriteError = 'Supabase not initialized.';
      return null;
    }

    await _ensureWriteSession();

    final candidates = _alertInsertCandidates(alert);
    for (final candidate in candidates) {
      final row = Map<String, dynamic>.from(candidate);
      while (true) {
        try {
          final rows = await Supabase.instance.client
              .from('emergency_alerts')
              .insert(row)
              .select()
              .limit(1) as List<dynamic>;
          if (rows.isEmpty) {
            return alert;
          }
          return _alertFromRow(rows.first as Map<String, dynamic>);
        } on PostgrestException catch (error) {
          final missingColumn = _extractMissingColumnNameForTable(
            tableName: 'emergency_alerts',
            message: error.message,
          );
          if (missingColumn != null && row.containsKey(missingColumn)) {
            row.remove(missingColumn);
            continue;
          }
          _lastWriteError = _compactError(error.message);
          break;
        } catch (error) {
          _lastWriteError = _compactError(error.toString());
          break;
        }
      }
    }

    try {
      final bearer = _restBearerToken();
      final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/emergency_alerts');
      for (final candidate in candidates) {
        final response = await http.post(
          uri,
          headers: <String, String>{
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer $bearer',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation',
          },
          body: jsonEncode(candidate),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = response.body.trim();
          if (body.isEmpty) {
            return alert;
          }
          final parsed = jsonDecode(body);
          if (parsed is List && parsed.isNotEmpty && parsed.first is Map<String, dynamic>) {
            return _alertFromRow(parsed.first as Map<String, dynamic>);
          }
          return alert;
        }
        _lastWriteError = _extractApiError(response.body) ??
            'Emergency alert insert failed (HTTP ${response.statusCode}).';
      }
    } catch (error) {
      _lastWriteError = _compactError(error.toString());
    }

    debugPrint('Supabase insertAlert failed: ${_lastWriteError ?? 'unknown error'}');
    return null;
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

  Future<bool> insertHelpPost(HelpPost post) async {
    if (!await _ensureInitialized()) {
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client.from('help_posts').insert(
            _helpPostToRow(post),
          );
      return true;
    } catch (error) {
      debugPrint('Supabase insertHelpPost failed: $error');
      return false;
    }
  }

  Future<bool> deleteHelpPost(String postId) async {
    if (!await _ensureInitialized()) {
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client
          .from('help_posts')
          .delete()
          .eq('id', postId);
      return true;
    } catch (error) {
      debugPrint('Supabase deleteHelpPost failed: $error');
      return false;
    }
  }

  Future<bool> deleteHelpComment(String commentId) async {
    if (!await _ensureInitialized()) {
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client
          .from('help_post_comments')
          .delete()
          .eq('id', commentId);
      return true;
    } catch (error) {
      debugPrint('Supabase deleteHelpComment failed: $error');
      return false;
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

  Future<bool> insertHelpComment(HelpComment comment) async {
    if (!await _ensureInitialized()) {
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client.from('help_post_comments').insert(
            _helpCommentToRow(comment),
          );
      return true;
    } catch (error) {
      debugPrint('Supabase insertHelpComment failed: $error');
      return false;
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

  Future<bool> insertDonation(DonationEntry entry) async {
    _lastWriteError = null;
    if (!await _ensureInitialized()) {
      _lastWriteError = 'Supabase not initialized.';
      return false;
    }
    final hasSession = await _ensureWriteSession();
    try {
      if (hasSession) {
        await Supabase.instance.client.from('donations').insert(
              _donationToRow(entry),
            );
        return true;
      }
    } catch (error) {
      // Fall through to REST fallback for anon-role projects.
      debugPrint('Supabase SDK insertDonation failed: $error');
    }

    try {
      final bearer = _restBearerToken();
      final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/donations');
      final response = await http.post(
        uri,
        headers: <String, String>{
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer $bearer',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(_donationToRow(entry)),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      _lastWriteError = _extractApiError(response.body) ??
          'Donation insert failed (HTTP ${response.statusCode}).';
      return false;
    } catch (error) {
      _lastWriteError = _compactError(error.toString());
      debugPrint('Supabase REST insertDonation failed: $error');
      return false;
    }
  }

  Future<bool> upsertDonation(DonationEntry entry) async {
    _lastWriteError = null;
    if (!await _ensureInitialized()) {
      _lastWriteError = 'Supabase not initialized.';
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client
          .from('donations')
          .upsert(_donationToRow(entry), onConflict: 'id');
      return true;
    } catch (error) {
      _lastWriteError = _compactError(error.toString());
      debugPrint('Supabase upsertDonation failed: $error');
      return false;
    }
  }

  Future<bool> deleteDonation(String donationId) async {
    _lastWriteError = null;
    if (!await _ensureInitialized()) {
      _lastWriteError = 'Supabase not initialized.';
      return false;
    }
    await _ensureWriteSession();
    try {
      await Supabase.instance.client
          .from('donations')
          .delete()
          .eq('id', donationId);
      return true;
    } catch (error) {
      _lastWriteError = _compactError(error.toString());
      debugPrint('Supabase deleteDonation failed: $error');
      return false;
    }
  }

  Future<String?> fetchAppSetting({required String key}) async {
    if (!isConfigured) {
      return null;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      return null;
    }
    try {
      final rows = await Supabase.instance.client
          .from('app_settings')
          .select('value')
          .eq('key', key)
          .limit(1) as List<dynamic>;
      if (rows.isEmpty) {
        return null;
      }
      return rows.first['value'] as String?;
    } catch (error) {
      debugPrint('Supabase fetchAppSetting failed: $error');
      return null;
    }
  }

  Future<bool> upsertAppSetting({
    required String key,
    required String value,
  }) async {
    _lastWriteError = null;
    if (!await _ensureInitialized()) {
      _lastWriteError = 'Supabase not initialized.';
      return false;
    }

    final hasSession = await _ensureWriteSession();
    if (hasSession) {
      try {
        await Supabase.instance.client.from('app_settings').upsert(
          <String, dynamic>{'key': key, 'value': value},
          onConflict: 'key',
        );
        return true;
      } catch (error) {
        debugPrint('Supabase SDK upsertAppSetting failed: $error');
      }
    }

    try {
      final bearer = _restBearerToken();
      final uri = Uri.parse('${SupabaseConfig.url}/rest/v1/app_settings');
      final response = await http.post(
        uri,
        headers: <String, String>{
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer $bearer',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: jsonEncode(<String, dynamic>{'key': key, 'value': value}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      _lastWriteError = _extractApiError(response.body) ??
          'App setting update failed (HTTP ${response.statusCode}).';
      return false;
    } catch (error) {
      _lastWriteError = _compactError(error.toString());
      debugPrint('Supabase REST upsertAppSetting failed: $error');
      return false;
    }
  }

  /// Compresses [bytes] to WebP (quality 82, max 900 px on longest side).
  /// Falls back to original bytes if compression fails or is unavailable.
  Future<({Uint8List bytes, String contentType, String ext})>
      _compressToWebP(Uint8List bytes, String originalFileName) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: 82,
        minWidth: 1,
        minHeight: 1,
        keepExif: false,
      );
      // Only use compressed result if it is actually smaller.
      if (compressed.isNotEmpty && compressed.length < bytes.length) {
        final baseName = originalFileName.contains('.')
            ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
            : originalFileName;
        return (
          bytes: Uint8List.fromList(compressed),
          contentType: 'image/webp',
          ext: '$baseName.webp',
        );
      }
    } catch (e) {
      debugPrint('WebP compression failed, using original: $e');
    }
    return (
      bytes: bytes,
      contentType: _detectImageContentType(bytes),
      ext: originalFileName,
    );
  }

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
  }) async {
    _lastUploadError = null;
    if (!await _ensureInitialized()) {
      _lastUploadError = 'Supabase not initialized.';
      return null;
    }

    // Compress to WebP before uploading to save Supabase storage + egress.
    final compressed = await _compressToWebP(bytes, fileName);
    final uploadBytes = compressed.bytes;
    final contentType = compressed.contentType;
    fileName = compressed.ext;

    final client = Supabase.instance.client;

    var path = '$folder/$fileName';
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await client.storage
            .from(_mediaBucket)
            .uploadBinary(
              path,
              uploadBytes,
              fileOptions: FileOptions(
                // 30-day browser cache; Cloudflare CDN will cache at edge.
                cacheControl: '2592000',
                upsert: false,
                contentType: contentType,
              ),
            );
            return path;
      } catch (error) {
        final text = error.toString().toLowerCase();
        final looksLikeConflict =
            text.contains('409') || text.contains('duplicate') || text.contains('already exists');
        if (looksLikeConflict && attempt == 0) {
          final timestamp = DateTime.now().microsecondsSinceEpoch;
          path = '$folder/${timestamp}_$fileName';
          continue;
        }
        debugPrint('Supabase SDK uploadImageBytes failed: $error');
      }
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final bearer = _restBearerToken();
        final encodedPath = path
            .split('/')
            .map(Uri.encodeComponent)
            .join('/');
        final uri = Uri.parse(
          '${SupabaseConfig.url}/storage/v1/object/$_mediaBucket/$encodedPath',
        );
        final response = await http.post(
          uri,
          headers: <String, String>{
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer $bearer',
            'Content-Type': contentType,
            'Cache-Control': '2592000',
          },
          body: uploadBytes,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return path;
        }

        final looksLikeConflict = response.statusCode == 409;
        if (looksLikeConflict && attempt == 0) {
          final timestamp = DateTime.now().microsecondsSinceEpoch;
          path = '$folder/${timestamp}_$fileName';
          continue;
        }

        _lastUploadError = _extractApiError(response.body) ??
            'Image upload failed (HTTP ${response.statusCode}).';
        return null;
      } catch (error) {
        _lastUploadError = _compactError(error.toString());
        debugPrint('Supabase REST uploadImageBytes failed: $error');
        return null;
      }
    }

    _lastUploadError = 'Image upload failed after retrying with a unique file name.';
    return null;
  }

  String _compactError(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 260) {
      return normalized;
    }
    return '${normalized.substring(0, 260)}...';
  }

  String _restBearerToken() {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      return accessToken;
    }
    return SupabaseConfig.anonKey;
  }

  String _detectImageContentType(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38 &&
        (bytes[4] == 0x37 || bytes[4] == 0x39) &&
        bytes[5] == 0x61) {
      return 'image/gif';
    }
    return 'application/octet-stream';
  }

  String? _extractApiError(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final message = parsed['message'] ?? parsed['error_description'] ?? parsed['error'];
        if (message is String && message.trim().isNotEmpty) {
          return _compactError(message);
        }
      }
      return _compactError(body);
    } catch (_) {
      return _compactError(body);
    }
  }

  Map<String, dynamic> _memberToRow(
    Member member, {
    String? ownerId,
    bool includeOwnerId = false,
  }) {
    final row = <String, dynamic>{
      'id': member.id,
      'name': member.name,
      'mobile_number': member.mobileNumber,
      'email': member.email,
      'user_id': member.userId,
      'password_hash': member.passwordHash,
      'mpin': member.mpin,
      'reference_mobile_number': member.referenceMobileNumber,
      'reference_member_name': member.referenceMemberName,
      'selfie_path': storagePathFromMediaValue(member.selfiePath),
      'id_card_photo_path': storagePathFromMediaValue(member.idCardPhotoPath),
      'home_district': member.homeDistrict,
      'home_state': member.homeState,
      'posting_district': member.postingDistrict,
      'posting_state': member.postingState,
      'posting_location': member.postingLocation,
      'department': member.department,
      'post_rank': member.postRank,
      'official_name': member.officialName,
      'batch_year': member.batchYear,
      'gender': member.gender,
      'marital_status': member.maritalStatus,
      'posting_category': member.postingCategory,
      'posting_work_as': member.postingWorkAs,
      'whatsapp_number': member.whatsappNumber,
      'calling_contact_number': member.callingContactNumber,
      'posting_place_location': member.postingPlaceLocation,
      'emergency_contact': member.emergencyContact,
      'home_village_mohalla': member.homeVillageMohalla,
      'home_gali_no': member.homeGaliNo,
      'home_post_office': member.homePostOffice,
      'home_police_station': member.homePoliceStation,
      'home_tehsil': member.homeTehsil,
      'home_village_location': member.homeVillageLocation,
      'live_latitude': member.liveLatitude,
      'live_longitude': member.liveLongitude,
      'live_location_updated_at': member.liveLocationUpdatedAt?.toIso8601String(),
      'last_login_at': member.lastLoginAt?.toIso8601String(),
      'appointment_date': member.appointmentDate.toIso8601String(),
      'role': member.role,
      'last_updated': member.lastUpdated.toIso8601String(),
      'password_updated_at': member.passwordUpdatedAt.toIso8601String(),
      'is_admin': member.isAdmin,
      'is_blocked': member.isBlocked,
      'is_approved': member.isApproved,
      'is_retired': member.isRetired,
      'retired_at': member.retiredAt?.toIso8601String(),
      'is_deleted': member.isDeleted,
      'deleted_at': member.deletedAt?.toIso8601String(),
      'pending_update_payload': member.pendingUpdatePayload,
      'previous_public_profile_snapshot': member.previousPublicProfileSnapshot,
    };

    if (includeOwnerId && ownerId != null && ownerId.isNotEmpty) {
      row['owner_id'] = ownerId;
    }

    return row;
  }

  Member _memberFromRow(Map<String, dynamic> row) {
    return Member.fromMap(<String, dynamic>{
      'id': row['id'] as String,
      'name': row['name'] as String,
      'mobileNumber': row['mobile_number'] as String,
      'email': row['email'] as String?,
      'userId': row['user_id'] as String,
      'passwordHash': row['password_hash'] as String,
      'mpin': row['mpin'] as String,
      'referenceMobileNumber':
          (row['reference_mobile_number'] as String?) ?? '',
      'referenceMemberName': row['reference_member_name'] as String?,
      'selfiePath': _normalizeMediaUrl(row['selfie_path'] as String?),
      'idCardPhotoPath': _normalizeMediaUrl(row['id_card_photo_path'] as String?),
      'homeDistrict': row['home_district'] as String,
      'homeState': row['home_state'] as String?,
      'postingDistrict': row['posting_district'] as String,
      'postingState': row['posting_state'] as String?,
      'postingLocation': row['posting_location'] as String,
      'department': row['department'] as String?,
      'postRank': row['post_rank'] as String?,
      'officialName': row['official_name'] as String?,
      'batchYear': row['batch_year'] as String?,
      'gender': row['gender'] as String?,
      'maritalStatus': row['marital_status'] as String?,
      'postingCategory': row['posting_category'] as String?,
      'postingWorkAs': row['posting_work_as'] as String?,
      'whatsappNumber': row['whatsapp_number'] as String?,
      'callingContactNumber': row['calling_contact_number'] as String?,
      'postingPlaceLocation': row['posting_place_location'] as String?,
      'emergencyContact': row['emergency_contact'] as String?,
      'homeVillageMohalla': row['home_village_mohalla'] as String?,
      'homeGaliNo': row['home_gali_no'] as String?,
      'homePostOffice': row['home_post_office'] as String?,
      'homePoliceStation': row['home_police_station'] as String?,
      'homeTehsil': row['home_tehsil'] as String?,
      'homeVillageLocation': row['home_village_location'] as String?,
      'liveLatitude': (row['live_latitude'] as num?)?.toDouble(),
      'liveLongitude': (row['live_longitude'] as num?)?.toDouble(),
      'liveLocationUpdatedAt': row['live_location_updated_at'] as String?,
      'lastLoginAt': row['last_login_at'] as String?,
      'appointmentDate': row['appointment_date'] as String,
      'role': row['role'] as String,
      'lastUpdated': row['last_updated'] as String,
      'passwordUpdatedAt': row['password_updated_at'] as String,
      'isAdmin': row['is_admin'] as bool? ?? false,
      'isBlocked': row['is_blocked'] as bool? ?? false,
      'isApproved': row['is_approved'] as bool? ?? (row['is_admin'] as bool? ?? false),
      'isRetired': row['is_retired'] as bool? ?? false,
      'retiredAt': row['retired_at'] as String?,
      'isDeleted': row['is_deleted'] as bool? ?? false,
      'deletedAt': row['deleted_at'] as String?,
      'pendingUpdatePayload': row['pending_update_payload'] as String?,
      'previousPublicProfileSnapshot':
          row['previous_public_profile_snapshot'] as String?,
    });
  }

  String? _normalizeMediaUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return rawUrl;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return value;
    }

    // Legacy rows may still point at an old Supabase project host.
    final expectedBase = Uri.parse(SupabaseConfig.url);
    final isSupabaseStoragePublicPath =
        uri.path.startsWith('/storage/v1/object/public/');
    if (!isSupabaseStoragePublicPath) {
      return value;
    }

    String normalized = value;
    if (uri.host != expectedBase.host) {
      normalized = uri
          .replace(
            scheme: expectedBase.scheme,
            host: expectedBase.host,
            port: expectedBase.hasPort ? expectedBase.port : null,
          )
          .toString();
    }
    // Rewrite to CDN host so all image loads go through Cloudflare cache.
    return CdnConfig.rewrite(normalized);
  }

  Member? _tryMemberFromRow(Map<String, dynamic> row) {
    try {
      return _memberFromRow(row);
    } catch (error) {
      final id = row['id'];
      debugPrint(
          'Skipping malformed member row${id != null ? ' ($id)' : ''}: $error');
      return null;
    }
  }

  List<String> _mobileCandidates(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const <String>[];
    }

    final lastTen =
        digits.length > 10 ? digits.substring(digits.length - 10) : digits;
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
    final ownerId = _writeOwnerId();
    return <String, dynamic>{
      'id': alert.id,
      'owner_id': ownerId,
      'member_id': alert.memberId,
      'member_name': alert.memberName,
      // Always write UTC with timezone to prevent server-side timezone drift.
      'timestamp': alert.timestamp.toUtc().toIso8601String(),
      'message': alert.message,
      'location': alert.location,
    };
  }

  List<Map<String, dynamic>> _alertInsertCandidates(EmergencyAlert alert) {
    final base = _alertToRow(alert);
    final createdAtVariant = Map<String, dynamic>.from(base)
      ..remove('timestamp')
      ..['created_at'] = alert.timestamp.toUtc().toIso8601String();
    return <Map<String, dynamic>>[
      base,
      createdAtVariant,
    ];
  }

  EmergencyAlert _alertFromRow(Map<String, dynamic> row) {
    final createdAtRaw = row['created_at'];
    final timestampRaw = row['timestamp'];
    final effectiveTimestamp = createdAtRaw ?? timestampRaw;

    return EmergencyAlert.fromMap(<String, dynamic>{
      'id': (row['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      'memberId':
          (row['member_id'] ?? row['owner_id'] ?? row['user_id'] ?? '').toString(),
      'memberName':
          (row['member_name'] ?? row['name'] ?? 'Unknown member').toString(),
      'timestamp': _parseEmergencyTimestamp(effectiveTimestamp),
      'message': (row['message'] ?? row['alert_message'] ?? '').toString(),
      'location': (row['location'] ?? row['posting_location'] ?? '').toString(),
    });
  }

  DateTime _parseEmergencyTimestamp(dynamic raw) {
    if (raw is DateTime) {
      return raw.toUtc();
    }

    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) {
      return DateTime.now().toUtc();
    }

    final hasTimezone = RegExp(r'(Z|[+-][0-9]{2}:[0-9]{2})$').hasMatch(text);
    if (hasTimezone) {
      return DateTime.parse(text).toUtc();
    }

    final parsed = DateTime.parse(text);
    // Legacy rows may come without timezone; treat as UTC for stable display.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  Map<String, dynamic> _helpPostToRow(HelpPost post) {
    final ownerId = _writeOwnerId();
    return <String, dynamic>{
      'id': post.id,
      'owner_id': ownerId,
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
      'createdAt': (row['created_at'] ?? '').toString(),
    });
  }

  Map<String, dynamic> _helpCommentToRow(HelpComment comment) {
    final ownerId = _writeOwnerId();
    return <String, dynamic>{
      'id': comment.id,
      'owner_id': ownerId,
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
      'createdAt': (row['created_at'] ?? '').toString(),
    });
  }

  Map<String, dynamic> _donationToRow(DonationEntry entry) {
    final ownerId = _writeOwnerId();
    return <String, dynamic>{
      'id': entry.id,
      'owner_id': ownerId,
      'member_id': entry.memberId,
      'member_name': entry.memberName,
      'member_mobile': entry.memberMobile,
      'amount': entry.amount,
      'upi_id': entry.upiId,
      'status': entry.status,
      'transaction_ref': entry.transactionRef,
      'note': entry.note,
      'screenshot_path': entry.screenshotPath,
      'reviewed_at': entry.reviewedAt?.toIso8601String(),
      'reviewed_by': entry.reviewedBy,
      'rejection_reason': entry.rejectionReason,
      'created_at': entry.createdAt.toIso8601String(),
    };
  }

  String _writeOwnerId() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null && currentUserId.trim().isNotEmpty) {
      return currentUserId.trim();
    }
    return _generateUuidV4();
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String twoDigits(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(twoDigits).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
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
      'screenshotPath': _normalizeMediaUrl(row['screenshot_path'] as String?),
      'reviewedAt': row['reviewed_at'] as String?,
      'reviewedBy': row['reviewed_by'] as String?,
      'rejectionReason': row['rejection_reason'] as String?,
      'createdAt': row['created_at'] as String,
    });
  }
}
