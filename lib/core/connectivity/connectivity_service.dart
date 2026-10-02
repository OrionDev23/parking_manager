enum ConnectivityStatus { online, offline, unknown }

abstract class ConnectivityService {
  ConnectivityStatus get status;
  Stream<ConnectivityStatus> get statusStream;
}
