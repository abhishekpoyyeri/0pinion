import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/argument_repository.dart';
import '../../data/models/argument.dart';

final opinionArgumentsProvider = StreamProvider.family<List<Argument>, String>((ref, opinionId) {
  final repository = ref.watch(argumentRepositoryProvider);
  return repository.watchArguments(opinionId);
});
