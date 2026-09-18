// Libs
import "dart:convert";

var ____FUNCS____;

// Platform
bool platformIsWeb(){
    return false;
}

// Platform name
String getPlatformName(){
    return "windows";
}

// To json
String toJson(obj){
    try{
        var json = jsonEncode(obj);
        return json;
    }catch(_){
        return "{}";
    }
}

// From json
dynamic fromJson(json){
    try{
        var obj = jsonDecode(json);
        return obj;
    }catch(_){
        return {};
    }
}

var ____CLASS____;

// Utils for Windows
class Utils_ {
    //
}