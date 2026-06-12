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
    final res = await _supabase
        .from('live_rooms')
        .select('*, profiles!live_rooms_host_id_fkey(username)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
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

