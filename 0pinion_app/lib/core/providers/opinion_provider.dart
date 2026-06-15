import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/models/opinion.dart';

final feedOpinionsProvider = StreamProvider<List<Opinion>>((ref) {
  final repository = ref.watch(opinionRepositoryProvider);
  return repository.watchFeedOpinions();
});

/// Cooking opinions â€” sorted by time-decay cooking score, top 20.
/// Posts must have >= 3 weighted engagement points to qualify.
final cookingOpinionsProvider = Provider<AsyncValue<List<Opinion>>>((ref) {
  final opinionsAsync = ref.watch(feedOpinionsProvider);
  return opinionsAsync.whenData((opinions) {
    final cooking = opinions
        .where((o) => o.isCooking)
        .toList()
      ..sort((a, b) => b.cookingScore.compareTo(a.cookingScore));
    return cooking.take(20).toList();
  });
});

final opinionsByZeroProvider = FutureProvider.family<List<Opinion>, String>((ref, zeroId) async {
  final repository = ref.watch(opinionRepositoryProvider);
  return repository.fetchOpinionsByZero(zeroId);
});
