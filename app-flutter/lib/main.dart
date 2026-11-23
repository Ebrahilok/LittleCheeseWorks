import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsStore store;
  try {
    store = await PrefsSettingsStore.open();
  } catch (_) {
    // Sin almacenamiento la app funciona igual, solo no recuerda los ajustes.
    store = MemorySettingsStore();
  }
  runApp(ProviderScope(
    overrides: [settingsStoreProvider.overrideWithValue(store)],
    child: const RobotCargaApp(),
  ));
}
