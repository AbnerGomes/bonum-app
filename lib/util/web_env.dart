/// Informações do ambiente quando o app roda no navegador.
/// No Android, a versão "stub" responde valores neutros.
library;

export 'web_env_stub.dart' if (dart.library.js_interop) 'web_env_web.dart';

enum WebPlatform { ios, android, desktop }
