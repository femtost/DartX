// Libs
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

var ____FFI____;

// --- C Function Signatures (Native) ---
typedef WebViewCreateC = Pointer<Void> Function(Int32 debug, Pointer<Void> window);
typedef WebViewNavigateC = Void Function(Pointer<Void> w, Pointer<Char> url);
typedef WebViewRunC = Void Function(Pointer<Void> w);
typedef WebViewEvalC = Void Function(Pointer<Void> w, Pointer<Char> js);
typedef WebViewDestroyC = Void Function(Pointer<Void> w);

// --- Dart Function Signatures (Managed) ---
typedef WebViewCreateDart = Pointer<Void> Function(int debug, Pointer<Void> window);
typedef WebViewNavigateDart = void Function(Pointer<Void> w, Pointer<Char> url);
typedef WebViewRunDart = void Function(Pointer<Void> w);
typedef WebViewEvalDart = void Function(Pointer<Void> w, Pointer<Char> js);
typedef WebViewDestroyDart = void Function(Pointer<Void> w);

var ____CLASS____;

// WebView for Windows
class WebView_ {
    late DynamicLibrary dl;

    // Create
    // ********************************************
    // WARN: RUN ONCE ONLY, MEMLEAK NOT TESTED YET.
    // ********************************************
    void create(){
        // 1. Open the compiled webview.dll file
        this.dl = DynamicLibrary.open('webview.dll');

        // 2. Map all the required lifecycle functions from the DLL
        final WebViewCreateDart webviewCreate = this.dl
            .lookup<NativeFunction<WebViewCreateC>>('webview_create')
            .asFunction();

        final WebViewNavigateDart webviewNavigate = this.dl
            .lookup<NativeFunction<WebViewNavigateC>>('webview_navigate')
            .asFunction();

        final WebViewRunDart webviewRun = this.dl
            .lookup<NativeFunction<WebViewRunC>>('webview_run')
            .asFunction();

        final WebViewEvalDart webviewEval = this.dl
            .lookup<NativeFunction<WebViewEvalC>>('webview_eval')
            .asFunction();

        final WebViewDestroyDart webviewDestroy = this.dl
            .lookup<NativeFunction<WebViewDestroyC>>('webview_destroy')
            .asFunction();
    }
}
