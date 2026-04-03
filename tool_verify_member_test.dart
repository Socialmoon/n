import 'package:supabase/supabase.dart';

Future<void> main() async {
  const url = 'https://mpfzclgtdworikwqwzea.supabase.co';
  const key = 'sb_publishable_nmR5V3k5WXT5hgI6fiCztg_8OS4i4ce';
  final client = SupabaseClient(url, key);
  await client.auth.signInAnonymously();
  final rows = await client.from('members').select('id,name,is_deleted,deleted_at').ilike('name', 'test') as List<dynamic>;
  print('MATCHED_AFTER=${rows.length}');
  for (final row in rows) {
    print(row);
  }
}
