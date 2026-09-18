// Libs
import "libs.dart";

var ____CLASS____;

// App class
class App {
    WebView_ screen = WebView_();
    
    // Ctor
    App();

    // Start the app
    void start(){
        screen.create();
    }
}

var ____CORE____;

// Main
void main(){
    print("DartX starting...");
    print("Platform name: ${getPlatformName()}");
    var app = new App();
    app.start();
}