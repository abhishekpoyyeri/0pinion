import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

final userProfileDetailsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseClientProvider);
  return await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
});

final profileStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'opinions': 0, 'arguments': 0, 'zeroes': 0, 'reputation': 0};
  final supabase = ref.watch(supabaseClientProvider);
  
  final profileRes = await supabase
      .from('profiles')
      .select('reputation_score')
      .eq('id', user.id)
      .maybeSingle();
  final reputation = profileRes != null ? (profileRes['reputation_score'] as int? ?? 0) : 0;
  
  final opinionsRes = await supabase
      .from('opinions')
      .select('id')
      .eq('author_id', user.id);
  
  final argumentsRes = await supabase
      .from('arguments')
      .select('id')
      .eq('author_id', user.id);
      
  final zeroesRes = await supabase
      .from('opinions')
      .select('zero_id')
      .eq('author_id', user.id);
  final uniqueZeroes = zeroesRes
      .map((item) => item['zero_id'] as String?)
      .where((id) => id != null)
      .toSet();

  return {
    'opinions': opinionsRes.length,
    'arguments': argumentsRes.length,
    'zeroes': uniqueZeroes.length,
    'reputation': reputation,
  };
});

final userArgumentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final supabase = ref.watch(supabaseClientProvider);
  final res = await supabase
      .from('arguments')
      .select('*, opinions(id, title)')
      .eq('author_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res);
});

final userZeroesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final supabase = ref.watch(supabaseClientProvider);
  
  final opinionsRes = await supabase
      .from('opinions')
      .select('zero_id')
      .eq('author_id', user.id);
  
  final zeroIds = opinionsRes
      .map((item) => item['zero_id'] as String?)
      .where((id) => id != null)
      .toSet()
      .toList();
      
  if (zeroIds.isEmpty) return [];
  
  final zeroesRes = await supabase
      .from('zeroes')
      .select()
      .inFilter('id', zeroIds);
      
  return List<Map<String, dynamic>>.from(zeroesRes);
});

