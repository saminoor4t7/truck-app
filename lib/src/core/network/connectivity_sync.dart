import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivitySync {
  const ConnectivitySync();

  Stream<List<ConnectivityResult>> watch() =>
      Connectivity().onConnectivityChanged;

  Future<List<ConnectivityResult>> check() async =>
      Connectivity().checkConnectivity();
}
