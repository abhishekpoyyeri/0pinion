import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';

final liveRoomRepositoryProvider = Provider<LiveRoomRepository>((ref) {
  return LiveRoomRepository(ref.watch(supabaseClientProvider));
});

final liveRoomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(liveRoomRepositoryProvider);
  return repo.fetchRooms();
});

class LiveRoomRepository {
  final SupabaseClient _supabase;

  LiveRoomRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    try {
      final res = await _supabase
          .from('live_rooms')
          .select('*, profiles(username)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      // Fallback: fetch without profile join
      final res = await _supabase
          .from('live_rooms')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    }
  }

  Future<void> createRoom({
    required String title,
    required String topic,
    required String hostId,
  }) async {
    await _supabase.from('live_rooms').insert({
      'title': title,
      'topic': topic,
      'host_id': hostId,
    });
  }
}

