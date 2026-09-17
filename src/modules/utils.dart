// Libs
// Platform-specific:
export '../stub.dart' // Non-web
    if (dart.library.io) 'dart:io';

export '../stub.dart' // Web
    if (dart.library.js_interop) 'dart:js_interop';

// Re-exports of platform specific
import "utils_.dart";
export "utils_.dart";

var ____FUNCS____;

// Crossplatform funcs here
// ...

var ____CLASS____;

// Crossplatform class
class Utils {
    //
}