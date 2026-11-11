// App start: read the stored session, and make sure no household data is
// left on the phone without one (security review M2).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/storage/app_database.dart';
import 'repositories/household_repository.dart';

/// Loads the stored session. Without one (signed out, or the token store was
/// unreadable and reset), cached household data is wiped. With one, dates
/// use the cached household's zone from the first frame.
Future<void> restoreSession(ProviderContainer container) async {
  final session = container.read(sessionManagerProvider);
  await session.load();
  if (!session.isSignedIn) {
    await container.read(appDatabaseProvider).clearUserData();
    return;
  }
  await container.read(householdRepositoryProvider).cached();
}
