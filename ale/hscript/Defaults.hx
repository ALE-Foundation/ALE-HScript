package ale.hscript;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import ale.hscript.errors.Error;

import haxe.Exception;
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

    public static final EXTENSION:String = '.hx';
    public static final COMPILED_EXTENSION:String = '.hxc';

    public static final SCRIPT_PATH:String = 'scripts/';
    public static final MODULE_PATH:String = 'classes/';

    public static final SCRIPT_NAME:String = 'ale_hscript';

    public static final ERROR_HANDLER:Dynamic -> String -> Void = (error, name) -> Log.trace('[ ERROR ] ' + name + ': ' + error?.toString() ?? error, null);
}