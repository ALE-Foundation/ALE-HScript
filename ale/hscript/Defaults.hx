package ale.hscript;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import haxe.Log;

class Defaults
{
    public static final FILE_CHECKER:String -> Bool = #if sys FileSystem.exists #else null #end ;
    public static final FILE_READER:String -> String = #if sys File.getContent #else null #end ;

    public static final IMPORTS:Array<Class<Dynamic>> = [
        Array,
        Date,
        DateTools,
        EReg,
        IntIterator,
        Lambda,
        List,
        Math,
        Reflect,
        Std,
        Type,
        StringBuf,
        StringTools,
        #if sys Sys, #end
        Xml
    ];
    public static final ABSTRACTS:Array<String> = [];
    public static final TYPEDEFS:Map<String, Class<Dynamic>> = [];
    public static final VARIABLES:Map<String, Dynamic> = [];

    public static final SCRIPT_EXTENSION:String = '.hx';
    public static final SCRIPT_PATH:String = 'scripts/';

    public static final MODULE_EXTENSION:String = '.hx';
    public static final MODULE_PATH:String = 'classes/';

    public static final INTERP_NAME:String = 'ALEHScript.hx';

    public static final ERROR_HANDLER:String -> Void = (e) -> Log.trace('[ ERROR ] ' + e, null);
}