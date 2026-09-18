// Libs
import "libs.dart";

var ____CLASS____;

// App class
class App {    
    // Ctor
    App();

    // Start the app
    Future<void> start() async{
        var html = await Fs.readFile("./frontend/index.html");
        // Don't await here, or it blocks this main thread.
        WebView_.create(html);

        // WebView_ has its own thread (isolate), main thread
        // is more from here
        setInterval((timer){
            // timer.tick
            // timer.cancel
            // WebView_.testNav();
        },5000);
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