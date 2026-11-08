package ale.hscript;

import haxe.io.Bytes;

class Config
{
    public static var FILE_CHECKER:String -> Bool;
    public static var CONTENT_READER:String -> String;

    public static var IMPORTS:Array<Class<Dynamic>>;
    public static var ABSTRACTS:Array<String>;
    public static var TYPEDEFS:Map<String, Class<Dynamic>>;
    public static var VARIABLES:Map<String, Dynamic>;
    
    public static var SCRIPT_EXTENSION:String;
    public static var MODULE_EXTENSION:String;

    public static var SCRIPT_PATH:String;
    public static var MODULE_PATH:String;

    public static var SCRIPT_NAME:String;

    public static var ERROR_HANDLER:Dynamic -> String -> Void;
    
    static function __init__()
        reset();

    public static function reset()
    {
        FILE_CHECKER = Defaults.FILE_CHECKER;
        CONTENT_READER = Defaults.CONTENT_READER;

        IMPORTS = Defaults.IMPORTS;
        ABSTRACTS = Defaults.ABSTRACTS;
        TYPEDEFS = Defaults.TYPEDEFS;
        VARIABLES = Defaults.VARIABLES;

        SCRIPT_EXTENSION = Defaults.SCRIPT_EXTENSION;
        MODULE_EXTENSION = Defaults.MODULE_EXTENSION;

        SCRIPT_PATH = Defaults.SCRIPT_PATH;
        MODULE_PATH = Defaults.MODULE_PATH;

        SCRIPT_NAME = Defaults.SCRIPT_NAME;

        ERROR_HANDLER = Defaults.ERROR_HANDLER;
    }
}