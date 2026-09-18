/// Libs
import 'dart:io';

// Class
class Fs {

    // Read file
    // Path is absolute or relative
    static Future<String> readFile(path) async{
        final content = await File(path).readAsString();
        return content;
    }
}