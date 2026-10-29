/// Canal de Android donde caen los avisos de FCM y los de primer plano.
abstract final class CanalAvisos {
  static const String id = 'capsoul_avisos';
  static const String metodo = 'capsoul/avisos';

  /// Android 13 (API 33) pide POST_NOTIFICATIONS en tiempo de ejecución.
  static bool debePedirPermiso(int sdkAndroid) => sdkAndroid >= 33;
}
