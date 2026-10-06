import 'web_env.dart';

/// Fora da web o app é nativo: nada a instalar.
bool webIsStandalone() => true;

WebPlatform webPlatform() => WebPlatform.android;
