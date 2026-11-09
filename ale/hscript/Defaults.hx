package ale.hscript;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import ale.hscript.errors.Error;

import haxe.io.Bytes;

import haxe.Exception;
import haxe.Log;

@:unreflective
@:noPrivateAccess
@:allow(ale.hscript.Config)
class Defaults
{
    static final FILE_CHECKER:String -> Bool = #if sys FileSystem.exists #else null #end ;
    static final CONTENT_READER:String -> String = #if sys File.getContent #else null #end ;

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
    static final TYPEDEFS:Map<String, Class<Dynamic>> = [];
    static final VARIABLES:Map<String, Dynamic> = [];

    static final SCRIPT_EXTENSION:String = '.hx';
    static final MODULE_EXTENSION:String = '.hxc';

    static final SCRIPT_PATH:String = 'scripts/';
    static final MODULE_PATH:String = 'classes/';

    static final SCRIPT_NAME:String = 'ale_hscript';

    static final TRACE:String -> Int -> Array<Dynamic> -> Void = (name, line, args) -> Log.trace(name + ':' + line + ': ' + args.join(', '), null);

    static final ERROR_HANDLER:Dynamic -> String -> Void = (error, name) -> Log.trace('[ ERROR ] ' + name + ': ' + error?.toString() ?? error, null);
}