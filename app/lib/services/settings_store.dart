import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/world.dart';

/// Lo que la app recuerda entre sesiones.
class AppSettings {
  const AppSettings({
    this.host = defaultHost,
    this.room = Room.standard,
    this.points = const [],
  });

  /// IP del ESP32 cuando funciona como punto de acceso propio.
  static const defaultHost = '192.168.4.1';

  final String host;
  final Room room;
  final List<SavedPoint> points;

  /// Devuelve los valores por defecto si el texto está dañado o es de otra versión.
  static AppSettings decode(String? raw) {
    if (raw == null) return const AppSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final room = Room.fromJson(json['room'] as Map<String, dynamic>);
      return AppSettings(
        host: json['host'] as String? ?? defaultHost,
        room: room.isValid ? room : Room.standard,
        points: [
          for (final p in json['points'] as List? ?? const [])
            SavedPoint.fromJson(p as Map<String, dynamic>),
        ],
      );
    } on FormatException {
      return const AppSettings();
    } on TypeError {
      return const AppSettings();
    }
  }

  String encode() => jsonEncode({
        'host': host,
        'room': room.toJson(),
        'points': [for (final p in points) p.toJson()],
      });
}

abstract class SettingsStore {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

/// No persiste nada: pruebas y respaldo si el almacenamiento no está disponible.
class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this._settings = const AppSettings()]);
  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

/// Guarda los ajustes en el almacenamiento del dispositivo.
class PrefsSettingsStore implements SettingsStore {
  PrefsSettingsStore(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'settings_v1';

  static Future<PrefsSettingsStore> open() async =>
      PrefsSettingsStore(await SharedPreferences.getInstance());

  @override
  AppSettings load() => AppSettings.decode(_prefs.getString(_key));

  @override
  Future<void> save(AppSettings settings) =>
      _prefs.setString(_key, settings.encode());
}

/// `main()` lo reemplaza por [PrefsSettingsStore]; en pruebas queda en memoria.
final settingsStoreProvider =
    Provider<SettingsStore>((ref) => MemorySettingsStore());
