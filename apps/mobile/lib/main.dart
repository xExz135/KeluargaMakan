import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/storage/app_database.dart';
import 'core/storage/key_value_store.dart';
import 'data/repositories/household_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicense);
  final db = AppDatabase.open();
  final settings = await DriftSettingsStore.open(db);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      keyValueStoreProvider.overrideWithValue(settings),
    ],
  );
  await container.read(sessionManagerProvider).load();
  // Dates use the household's zone from the start when it is cached.
  await container.read(householdRepositoryProvider).cached();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KeluargaMakanApp(),
    ),
  );
}

Stream<LicenseEntry> _fontLicense() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], text);
}
