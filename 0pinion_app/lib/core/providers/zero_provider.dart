import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/zero_repository.dart';

/// Provide a zero by name
final zeroByNameProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, name) async {
  final repo = ref.watch(zeroRepositoryProvider);
  return repo.findByName(name);
});
