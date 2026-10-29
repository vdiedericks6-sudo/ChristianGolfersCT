/// Picks the web or non-web implementation at compile time.
///
/// `flutter_web_plugins` only exists on web, so importing it unconditionally
/// breaks the Android and iOS builds. go_router used to re-export
/// `usePathUrlStrategy` for exactly this reason, but dropped it in v17.
library;
export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
