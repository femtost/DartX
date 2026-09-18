// Libs
import "dart:async";

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

// Create async lock
(Future<T>, void Function(T)) newLock<T>() {
    final completer = Completer<T>();
    return (completer.future, (T result) => completer.complete(result));
}

// Sleep
Future<void> sleepMs(int milliseconds) {
    return Future.delayed(Duration(milliseconds: milliseconds));
}

// setInterval the JS style
Timer setInterval(callback,ms){
    return Timer.periodic(Duration(milliseconds: ms), (timer) {
        // Tick count: timer.tick
        // Stop timer: timer.cancel()
        callback(timer);
    });
}

var ____CLASS____;

// Crossplatform class
class Utils {
    //
}