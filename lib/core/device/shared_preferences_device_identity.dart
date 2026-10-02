import 'package:shared_preferences/shared_preferences.dart';
import 'device_identity.dart';

class SharedPreferencesDeviceIdentity implements DeviceIdentity {
  static const _key = 'parcoto_device_id';
  final Future<SharedPreferences> _preferences;
  final String Function() idFactory;
  SharedPreferencesDeviceIdentity(this._preferences, {required this.idFactory});

  @override
  Future<String> getDeviceId() async {
    final prefs = await _preferences;
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = idFactory();
    await prefs.setString(_key, id);
    return id;
  }
}
