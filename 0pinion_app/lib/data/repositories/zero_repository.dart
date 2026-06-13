import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';

final zeroRepositoryProvider = Provider<ZeroRepository>((ref) {
  return ZeroRepository(ref.watch(supabaseClientProvider));
});

class ZeroRepository {
  final SupabaseClient _supabase;

  ZeroRepository(this._supabase);

  /// Find a zero by exact name (case-insensitive)
  Future<Map<String, dynamic>?> findByName(String name) async {
    final res = await _supabase
        .from('zeroes')
        .select()
        .ilike('name', name)
        .maybeSingle();
    return res;
  }

  /// Find an existing zero or create a new one. Returns the zero's UUID.
  Future<String> findOrCreate(String name) async {
    // 1. Try to find existing
    final existing = await findByName(name);
    if (existing != null) {
      return existing['id'] as String;
    }

    // 2. Create new zero
    final res = await _supabase
        .from('zeroes')
        .insert({'name': name})
        .select('id')
        .single();
    return res['id'] as String;
  }

  /// Fetch all zeroes
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final res = await _supabase
        .from('zeroes')
        .select()
        .order('opinions_count', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
