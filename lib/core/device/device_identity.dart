abstract class DeviceIdentity {
  Future<String> getDeviceId();
}

class PersistentDeviceIdentity implements DeviceIdentity {
  final String Function() idFactory;
  String? _id;

  PersistentDeviceIdentity({required this.idFactory});

  @override
  Future<String> getDeviceId() async => _id ??= idFactory();
}
