import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

// --- FFI Bindings Definitions for webview.dll ---
typedef webview_create_native = ffi.Pointer<ffi.Void> Function(ffi.Int32 debug, ffi.Pointer<ffi.Void> window);
typedef WebviewCreate = ffi.Pointer<ffi.Void> Function(int debug, ffi.Pointer<ffi.Void> window);

typedef webview_navigate_native = ffi.Void Function(ffi.Pointer<ffi.Void> w, ffi.Pointer<Utf8> url);
typedef WebviewNavigate = void Function(ffi.Pointer<ffi.Void> w, ffi.Pointer<Utf8> url);

typedef webview_run_native = ffi.Void Function(ffi.Pointer<ffi.Void> w);
typedef WebviewRun = void Function(ffi.Pointer<ffi.Void> w);

typedef webview_destroy_native = ffi.Void Function(ffi.Pointer<ffi.Void> w);
typedef WebviewDestroy = void Function(ffi.Pointer<ffi.Void> w);

typedef webview_terminate_native = ffi.Void Function(ffi.Pointer<ffi.Void> w);
typedef WebviewTerminate = void Function(ffi.Pointer<ffi.Void> w);

// The C Callback signature used by webview_dispatch: void fn(webview_t w, void *arg)
typedef webview_dispatch_fn_native = ffi.Void Function(ffi.Pointer<ffi.Void> w, ffi.Pointer<ffi.Void> arg);

// webview_dispatch C function signature
typedef webview_dispatch_native = ffi.Void Function(
    ffi.Pointer<ffi.Void> w, 
    ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>> fn, 
    ffi.Pointer<ffi.Void> arg
);
typedef WebviewDispatch = void Function(
    ffi.Pointer<ffi.Void> w, 
    ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>> fn, 
    ffi.Pointer<ffi.Void> arg
);

// Configuration passed to the background stdin listener isolate
class StdinWorkerConfig {
    final int webviewAddress;
    final int callbackAddress;
    final int terminateCallbackAddress;
    StdinWorkerConfig(this.webviewAddress, this.callbackAddress, this.terminateCallbackAddress);
}

// Top-level dispatch callback for navigation executed on the main UI thread
void onNativeDispatch(ffi.Pointer<ffi.Void> webviewInstance, ffi.Pointer<ffi.Void> urlArgPointer) {
    if (urlArgPointer == ffi.nullptr || webviewInstance == ffi.nullptr) return;

    // 1. Cast the raw generic pointer back into a UTF-8 C-String pointer
    final ffi.Pointer<Utf8> urlStringPointer = urlArgPointer.cast<Utf8>();
    final String urlString = urlStringPointer.toDartString();

    print('[WebView UI Thread] Navigating to: $urlString');

    // 2. Perform the navigation action inside the main GUI execution loop thread context
    final dylib = ffi.DynamicLibrary.open('webview.dll');
    final WebviewNavigate webviewNavigate = dylib.lookupFunction<webview_navigate_native, WebviewNavigate>('webview_navigate');

    webviewNavigate(webviewInstance, urlStringPointer);

    // 3. Free the string memory allocated on the heap during the dispatch call setup
    calloc.free(urlStringPointer);
}

// Top-level dispatch callback for termination executed on the main UI thread
void onNativeTerminate(ffi.Pointer<ffi.Void> webviewInstance, ffi.Pointer<ffi.Void> arg) {
    if (webviewInstance == ffi.nullptr) return;

    print('[WebView UI Thread] Terminating webview loop...');
    final dylib = ffi.DynamicLibrary.open('webview.dll');
    final WebviewTerminate webviewTerminate = dylib.lookupFunction<webview_terminate_native, WebviewTerminate>('webview_terminate');

    webviewTerminate(webviewInstance);
}

// Background isolate entry point for non-blocking stdin listening.
// Reading stdin in a separate isolate ensures the console remains fully responsive
// even while the main isolate's thread is blocked in webviewRun.
void _stdinListener(StdinWorkerConfig config) {
    final dylib = ffi.DynamicLibrary.open('webview.dll');
    final WebviewDispatch webviewDispatch = dylib.lookupFunction<webview_dispatch_native, WebviewDispatch>('webview_dispatch');

    final webviewInstance = ffi.Pointer<ffi.Void>.fromAddress(config.webviewAddress);
    final dispatchCallback = ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>>.fromAddress(config.callbackAddress);
    final terminateCallback = ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>>.fromAddress(config.terminateCallbackAddress);

    while (true) {
        final line = stdin.readLineSync();
        if (line == null) break;

        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.toLowerCase() == 'exit' || trimmed.toLowerCase() == 'quit') {
            print('[Stdin] Received exit command, closing webview...');
            webviewDispatch(webviewInstance, terminateCallback, ffi.nullptr);
            break;
        }

        String targetUrl = trimmed;
        if (!targetUrl.startsWith('http://') && 
            !targetUrl.startsWith('https://') && 
            !targetUrl.startsWith('file://')) {
            targetUrl = 'https://$targetUrl';
        }

        print('[Stdin] Input received ("$trimmed"), dispatching to: $targetUrl');

        // Allocate a UTF-8 representation of our string directly on the native heap.
        // This is freed inside `onNativeDispatch` once the main thread handles navigation.
        final ffi.Pointer<Utf8> urlNativeStringHeap = targetUrl.toNativeUtf8();
        webviewDispatch(
            webviewInstance,
            dispatchCallback,
            urlNativeStringHeap.cast<ffi.Void>()
        );
    }
}

void main() async {
    final String dllPath = 'webview.dll';
    if (!File(dllPath).existsSync()) {
        print('Error: webview.dll not found in the current directory!');
        return;
    }

    final dylib = ffi.DynamicLibrary.open(dllPath);

    final WebviewCreate webviewCreate = dylib.lookupFunction<webview_create_native, WebviewCreate>('webview_create');
    final WebviewRun webviewRun = dylib.lookupFunction<webview_run_native, WebviewRun>('webview_run');
    final WebviewDestroy webviewDestroy = dylib.lookupFunction<webview_destroy_native, WebviewDestroy>('webview_destroy');
    final WebviewNavigate webviewNavigate = dylib.lookupFunction<webview_navigate_native, WebviewNavigate>('webview_navigate');

    print('Initializing native Webview context...');
    final ffi.Pointer<ffi.Void> webviewInstance = webviewCreate(0, ffi.nullptr);

    // Load the initial home layout page safely
    final initialUrlPtr = 'https://www.google.com'.toNativeUtf8();
    webviewNavigate(webviewInstance, initialUrlPtr);
    calloc.free(initialUrlPtr);

    // Convert our top-level Dart functions into active C function pointer structures
    final ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>> dispatchCallbackPointer = 
        ffi.Pointer.fromFunction<webview_dispatch_fn_native>(onNativeDispatch);
    final ffi.Pointer<ffi.NativeFunction<webview_dispatch_fn_native>> terminateCallbackPointer = 
        ffi.Pointer.fromFunction<webview_dispatch_fn_native>(onNativeTerminate);

    // Start background isolate to listen for stdin input.
    // Because webviewRun blocks the main thread with a native message loop,
    // console input must be read in a separate isolate so it stays responsive.
    await Isolate.spawn(
        _stdinListener,
        StdinWorkerConfig(
            webviewInstance.address,
            dispatchCallbackPointer.address,
            terminateCallbackPointer.address
        )
    );

    print('\n======================================================');
    print('Webview Running via Webview_Dispatch Queue!');
    print('Type a URL here and press Enter (or type "exit" to quit):');
    print('Example: pub.dev or github.com');
    print('======================================================\n');

    // Blocks the main process loop frame natively, while the background isolate routes inputs via webview_dispatch
    webviewRun(webviewInstance);

    webviewDestroy(webviewInstance);
    exit(0);
}
