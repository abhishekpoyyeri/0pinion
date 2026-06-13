import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';

final liveRoomRepositoryProvider = Provider<LiveRoomRepository>((ref) {
  return LiveRoomRepository(ref.watch(supabaseClientProvider));
});

final liveRoomsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(liveRoomRepositoryProvider);
  // Clean up expired rooms first, then fetch
  await repo.deleteExpiredRooms();
  return repo.fetchRooms();
});

class LiveRoomRepository {
  final SupabaseClient _supabase;

  LiveRoomRepository(this._supabase);

  /// Fetch rooms that are either:
  /// - active (not closed)
  /// - closed within the last 3 hours (showing conclusion)
  /// Also auto-close rooms that have exceeded their duration
  Future<List<Map<String, dynamic>>> fetchRooms() async {
    try {
      final res = await _supabase
          .from('live_rooms')
          .select('*, profiles(username)')
          .order('created_at', ascending: false);

      final rooms = List<Map<String, dynamic>>.from(res);

      // Auto-close rooms that have exceeded their duration but are still 'active'
      for (final room in rooms) {
        if (room['status'] == 'active') {
          final createdAt = DateTime.parse(room['created_at'] as String);
          final duration = room['duration_minutes'] as int? ?? 10;
          final endTime = createdAt.add(Duration(minutes: duration));
          if (DateTime.now().isAfter(endTime)) {
            // Auto-close this room
            try {
              await _supabase
                  .from('live_rooms')
                  .update({
                    'status': 'closed',
                    'closed_at': DateTime.now().toIso8601String(),
                    'conclusion': 'Room timed out — no conclusion was provided.',
                  })
                  .eq('id', room['id']);
              room['status'] = 'closed';
              room['closed_at'] = DateTime.now().toIso8601String();
              room['conclusion'] = 'Room timed out — no conclusion was provided.';
            } catch (_) {
              // If we can't update (not host), just mark locally
              room['status'] = 'closed';
            }
          }
        }
      }

      // Filter: show active rooms + closed rooms within 3 hours
      final now = DateTime.now();
      return rooms.where((room) {
        if (room['status'] == 'active') return true;
        if (room['status'] == 'closed' && room['closed_at'] != null) {
          final closedAt = DateTime.parse(room['closed_at'] as String);
          return now.difference(closedAt).inHours < 3;
        }
        return false;
      }).toList();
    } catch (_) {
      // Fallback: fetch without profile join
      final res = await _supabase
          .from('live_rooms')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    }
  }

  /// Create a new room with a specific duration
  Future<void> createRoom({
    required String title,
    required String topic,
    required String hostId,
    int durationMinutes = 10,
  }) async {
    await _supabase.from('live_rooms').insert({
      'title': title,
      'topic': topic,
      'host_id': hostId,
      'duration_minutes': durationMinutes,
    });
  }

  /// Close a room with a conclusion (host only)
  Future<void> closeRoom({
    required String roomId,
    required String conclusion,
  }) async {
    await _supabase
        .from('live_rooms')
        .update({
          'status': 'closed',
          'closed_at': DateTime.now().toIso8601String(),
          'conclusion': conclusion,
        })
        .eq('id', roomId);
  }

  /// Delete rooms that have been closed for more than 3 hours
  Future<void> deleteExpiredRooms() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 3));
      await _supabase
          .from('live_rooms')
          .delete()
          .eq('status', 'closed')
          .lt('closed_at', cutoff.toIso8601String());
    } catch (_) {
      // Silent fail — user might not be the host of expired rooms
    }
  }

  /// Fetch a single room by ID
  Future<Map<String, dynamic>?> fetchRoom(String roomId) async {
    return await _supabase
        .from('live_rooms')
        .select('*, profiles(username)')
        .eq('id', roomId)
        .maybeSingle();
  }
}
