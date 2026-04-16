import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/features/group_planning/data/group_planning_repository.dart';

final groupPlanningRepositoryProvider =
    Provider<GroupPlanningRepository>((ref) {
  return GroupPlanningRepository(Supabase.instance.client);
});
