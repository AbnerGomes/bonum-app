import 'dart:js_interop';

import 'web_env.dart';

// Funções definidas em web/index.html.
@JS('bonumIsStandalone')
external JSBoolean _isStandalone();

@JS('bonumPlatform')
external JSString _platform();

/// true quando aberto pelo ícone da tela inicial (app instalado).
bool webIsStandalone() {
  try {
    return _isStandalone().toDart;
  } catch (_) {
    return false;
  }
}

WebPlatform webPlatform() {
  try {
    switch (_platform().toDart) {
      case 'ios':
        return WebPlatform.ios;
      case 'android':
        return WebPlatform.android;
    }
  } catch (_) {}
  return WebPlatform.desktop;
}
