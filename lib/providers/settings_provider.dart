import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user settings, persisted via SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  static const _keyOnDeviceOnly = 'on_device_only';
  static const _keyModelName = 'model_name';

  bool _onDeviceOnly = true;
  bool get onDeviceOnly => _onDeviceOnly;

  String _modelName = 'CrashLens Mock Engine v1.0';
  String get modelName => _modelName;

  String get modelSize => _onDeviceOnly ? '< 1 MB (mock)' : 'Cloud API';
  String get modelStatus => _onDeviceOnly ? 'Active — on-device' : 'Cloud fallback enabled';

  bool _initialized = false;

  /// Load settings from SharedPreferences.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _onDeviceOnly = prefs.getBool(_keyOnDeviceOnly) ?? true;
    _modelName = prefs.getString(_keyModelName) ?? 'CrashLens Mock Engine v1.0';
    _initialized = true;
    notifyListeners();
  }

  /// Toggle on-device / cloud-fallback mode.
  Future<void> setOnDeviceOnly(bool value) async {
    _onDeviceOnly = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnDeviceOnly, value);
  }
}
