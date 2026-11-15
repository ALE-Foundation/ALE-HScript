package ale.hscript;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import ale.hscript.errors.Error;

import haxe.io.Bytes;

import haxe.Exception;
import haxe.Log;

@:noPrivateAccess
@:allow(ale.hscript.Config)
class Defaults
{
    static final MODULE_IMPORT_CALLBACK:String -> Void = Defaults.MODULE_IMPORT_CALLBACK;

    static final FILE_CHECKER:String -> Bool = #if sys FileSystem.exists #else null #end ;
    static final FILE_READER:String -> String = #if sys File.getContent #else null #end ;

    static final IMPORTS:Array<Class<Dynamic>> = [
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
    static final ABSTRACTS:Array<String> = [];
    static final ENUMS:Array<String> = [];
    static final TYPEDEFS:Map<String, Class<Dynamic>> = [
        'Map' => haxe.ds.ObjectMap
    ];
    static final VARIABLES:Map<String, Dynamic> = [];

    static final SCRIPT_EXTENSION:String = '.hx';
    static final MODULE_EXTENSION:String = '.hx';

    static final SCRIPT_PATH:String = 'scripts/';
    static final MODULE_PATH:String = 'modules/';

    static final SCRIPT_NAME:String = 'ale_hscript';

    static final SCRIPT_TRACE:(String, Int, Array<Dynamic>) -> Void = (name, line, args) -> Log.trace(name + ':' + line + ': ' + args.join(', '), null);

    static final ERROR_HANDLER:(String, Dynamic) -> Void = (name, error) -> Log.trace('[ ERROR ] ' + name + ': ' + Std.string(error), null);
    static final HANDLE_ERRORS:Bool = true;
}