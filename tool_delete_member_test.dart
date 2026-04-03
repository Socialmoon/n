import 'dart:async';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  const url = 'https://mpfzclgtdworikwqwzea.supabase.co';
  const key = 'sb_publishable_nmR5V3k5WXT5hgI6fiCztg_8OS4i4ce';
  final client = SupabaseClient(url, key);

  await client.auth.signInAnonymously();
  final session = client.auth.currentSession;
  if (session == null) {
    throw Exception('Could not create authenticated anonymous session.');
  }

  final before = await client
      .from('members')
      .select('id,name,is_deleted')
      .ilike('name', 'test') as List<dynamic>;

  print('MATCHED_BEFORE=${before.length}');
  if (before.isEmpty) {
    print('No member with name test found.');
    return;
  }

  try {
    final hardDeleted = await client
        .from('members')
        .delete()
        .ilike('name', 'test')
        .select('id,name') as List<dynamic>;
    print('HARD_DELETE_COUNT=${hardDeleted.length}');
    return;
  } catch (e) {
    print('HARD_DELETE_BLOCKED=$e');
  }

  final softUpdated = await client
      .from('members')
      .update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      })
      .ilike('name', 'test')
      .select('id,name,is_deleted') as List<dynamic>;

  print('SOFT_DELETE_COUNT=${softUpdated.length}');
}
