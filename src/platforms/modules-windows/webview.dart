// Libs
import 'dart:ffi';
import 'dart:convert';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

var ____FFI____;

// --- C Function Signatures (Native) ---
typedef WebViewCreateC = Pointer<Void> Function(Int32 debug, Pointer<Void> window);
typedef WebViewNavigateC = Void Function(Pointer<Void> w, Pointer<Char> url);
typedef WebViewRunC = Void Function(Pointer<Void> w);
typedef WebViewEvalC = Void Function(Pointer<Void> w, Pointer<Char> js);
typedef WebViewDestroyC = Void Function(Pointer<Void> w);

typedef WebViewBindCallbackC = Void Function(Pointer<Char> id,Pointer<Char> req,Pointer<Void> arg);
typedef WebViewBindC = Int32 Function(Pointer<Void> w,Pointer<Char> name,
    Pointer<NativeFunction<WebViewBindCallbackC>> fn,Pointer<Void> arg);

typedef WebViewReturnC = Int32 Function(Pointer<Void> w,Pointer<Char> id,Int32 status,
    Pointer<Char> result);

typedef WebViewDispatchCallbackC = Void Function(Pointer<Void> w,Pointer<Void> arg);
typedef WebViewDispatchC = Void Function(Pointer<Void> w,Pointer<NativeFunction<WebViewDispatchCallbackC>> fn,
    Pointer<Void> arg);

// --- Dart Function Signatures (Managed) ---
typedef WebViewCreateDart = Pointer<Void> Function(int debug, Pointer<Void> window);
typedef WebViewNavigateDart = void Function(Pointer<Void> w, Pointer<Char> url);
typedef WebViewRunDart = void Function(Pointer<Void> w);
typedef WebViewEvalDart = void Function(Pointer<Void> w, Pointer<Char> js);
typedef WebViewDestroyDart = void Function(Pointer<Void> w);

typedef WebViewBindCallbackDart = void Function(Pointer<Char> id,Pointer<Char> req,Pointer<Void> arg);
typedef WebViewBindDart = int Function(Pointer<Void> w,Pointer<Char> name,
    Pointer<NativeFunction<WebViewBindCallbackC>> fn,Pointer<Void> arg);

typedef WebViewReturnDart = int Function(Pointer<Void> w,Pointer<Char> id,int status,
    Pointer<Char> result);

typedef WebViewDispatchCallbackDart = void Function(Pointer<Void> w,Pointer<Void> arg);
typedef WebViewDispatchDart = void Function(Pointer<Void> w,Pointer<NativeFunction<WebViewDispatchCallbackC>> fn,
    Pointer<Void> arg);

var ____CLASS____;

// WebView for Windows
// See: https://github.com/webview/webview/blob/master/core/include/webview/api.h
// Communication: 
//   - JS -> Dart: webview_bind + webview_return
//   - Dart -> JS: webview_eval + wait for webview_bind call.
class WebView_ {
    // late DynamicLibrary dl; // Inside isolate, can't pass in
    // late DynamicLibrary dlOuter;
    static late Pointer<Void> webview; // Inside isolate, passed out
    static late WebViewNavigateDart webviewNavigate;
    static late WebViewEvalDart webviewEval;
    static late WebViewReturnDart webviewReturn;
    static late WebViewDispatchDart webviewDispatch;

    // Test nav
    static void testNav() {
        print("Test nav dispatching...");
        final dispatchCallback =
            Pointer.fromFunction<WebViewDispatchCallbackC>(_thisclass.onDispatch);
        _thisclass.webviewDispatch(
            _thisclass.webview,dispatchCallback,nullptr
        );
        print("Dispatched");
    }

    // Dispatch message to webview
    static void onDispatch(Pointer<Void> w,Pointer<Void> arg) {
        print('DISPATCH CALLBACK');

        final js = "window.open('https://www.google.com','_self');"
            .toNativeUtf8();
        _thisclass.webviewEval(w, js.cast<Char>());
        calloc.free(js);
    }

    // Testing
    static void onFoobar(Pointer<Char> id,Pointer<Char> req,Pointer<Void> arg) {
        print('id: ${id.cast<Utf8>().toDartString()}');
        print('req: ${req.cast<Utf8>().toDartString()}');

        // // This reach JS side, seems webview_run blocks the webview thread:
        // print("Eval'ing...");
        // final js = "window.open('https://www.google.com','_self');".toNativeUtf8();
        // webviewEval(webview,js.cast<Char>());
        // calloc.free(js);
        // print("Evaled");

        // // Even in onDispatch, eval doesn't reach JS side
        // print("Dispatching eval...");
        // final dispatchCallback =
        //     Pointer.fromFunction<WebViewDispatchCallbackC>(_thisclass.onDispatch);
        // _thisclass.webviewDispatch(
        //     _thisclass.webview,dispatchCallback,nullptr
        // );
        // print("Dispatched");

        // This reach JS side, seems webview_run blocks the webview thread:
        print("Returning...");
        final result = jsonEncode({'called': "yes"});
        final resultPtr = result.toNativeUtf8();
        webviewReturn(_thisclass.webview, id, 0, resultPtr.cast<Char>());
        calloc.free(resultPtr);        
        print("Returned");
    }

    // Create
    // ********************************************
    // WARN: RUN ONCE ONLY, MEMLEAK NOT TESTED YET.
    // ********************************************
    static Future<void> create(String html) async{
        // Receive webview of its own thread inside isolate
        final receiver = ReceivePort(); 

        receiver.listen((map) {
            print('Object from isolate: $map');
            _thisclass.webview = Pointer.fromAddress(map["webview"]);
            _thisclass.webviewNavigate = map["webviewNavigate"];
            _thisclass.webviewEval = map["webviewEval"];
            _thisclass.webviewDispatch = map["webviewDispatch"]; 
            print("WebView2 is at: ${_thisclass.webview}");            
        });

        // New thread
        await Isolate.spawn(
            (SendPort sendPort){
                // 1. Open the compiled webview.dll file
                final dl = DynamicLibrary.open('webview.dll');

                // 2. Map all the required lifecycle functions from the DLL
                final WebViewCreateDart webviewCreate = dl
                    .lookup<NativeFunction<WebViewCreateC>>('webview_create')
                    .asFunction();
                final WebViewNavigateDart webviewNavigate = dl
                    .lookup<NativeFunction<WebViewNavigateC>>('webview_navigate')
                    .asFunction();
                final WebViewRunDart webviewRun = dl
                    .lookup<NativeFunction<WebViewRunC>>('webview_run')
                    .asFunction();
                final WebViewEvalDart webviewEval = dl
                    .lookup<NativeFunction<WebViewEvalC>>('webview_eval')
                    .asFunction();
                final WebViewDestroyDart webviewDestroy = dl
                    .lookup<NativeFunction<WebViewDestroyC>>('webview_destroy')
                    .asFunction();
                final WebViewBindDart webviewBind = dl
                    .lookup<NativeFunction<WebViewBindC>>('webview_bind')
                    .asFunction();
                final webviewReturn = dl
                    .lookup<NativeFunction<WebViewReturnC>>('webview_return')
                    .asFunction<WebViewReturnDart>();   
                final webviewDispatch = dl
                    .lookup<NativeFunction<WebViewDispatchC>>('webview_dispatch')
                    .asFunction<WebViewDispatchDart>();

                // Make data url
                var dataUrl = "data:text/html;charset=utf-8,${Uri.encodeComponent(html)}";

                // 3. Create the top-level WebView2 window context
                // Debug mode is set to 0 (false), parent window is nullptr
                final Pointer<Void> webview = webviewCreate(0, nullptr);

                if (webview == nullptr) {
                    print("Failed to initialize webview instance.");
                    return;
                }
                sendPort.send({
                    "webview": webview.address,
                    "webviewNavigate": webviewNavigate,
                    "webviewEval": webviewEval,
                    "webviewReturn": webviewReturn,
                    "webviewDispatch": webviewDispatch
                });

                // Testing
                final onFoobarCallback = 
                    Pointer.fromFunction<WebViewBindCallbackC>(_thisclass.onFoobar);
                final name = 'foobar'.toNativeUtf8();
                webviewBind(webview,name.cast<Char>(),onFoobarCallback,nullptr);
                calloc.free(name);

                // 4. Navigate to your target page
                final urlPointer = dataUrl.toNativeUtf8();
                webviewNavigate(webview, urlPointer.cast<Char>());
                calloc.free(urlPointer);                            

                // Testing (this causes crash after webview window closed)
                // This is blocked by webview_run but may (may only) get trigged 
                // if any webview_bind is fired.
                /*Future.delayed((Duration(milliseconds: 3000)),(){
                    print("Test changing url");
                    final js = "window.open('https://www.google.com','_self');".toNativeUtf8();
                    webviewEval(webview,js.cast<Char>());
                    calloc.free(js);
                });*/

                // 5. Start the blocking Win32 window message loop
                print("Opening WebView2 window...");
                webviewRun(webview);

                // 6. Clean up memory once the user closes the window
                webviewDestroy(webview);
            },receiver.sendPort);
    } // create
}
typedef _thisclass = WebView_;
