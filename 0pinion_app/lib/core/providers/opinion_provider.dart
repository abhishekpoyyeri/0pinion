import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/models/opinion.dart';

final feedOpinionsProvider = StreamProvider<List<Opinion>>((ref) {
  final repository = ref.watch(opinionRepositoryProvider);
  return repository.watchFeedOpinions();
});
