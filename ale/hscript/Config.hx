package ale.hscript;

import haxe.io.Bytes;

class Config
{
    public static var FILE_CHECKER:String -> Bool = Defaults.FILE_CHECKER;
    
    public static var CONTENT_READER:String -> String = Defaults.CONTENT_READER;
    public static var BYTES_READER:String -> Bytes = Defaults.BYTES_READER;
    
    public static var BYTES_WRITER:String -> Bytes -> Void = Defaults.BYTES_WRITER;

    public static var IMPORTS:Array<Class<Dynamic>> = Defaults.IMPORTS;
    public static var ABSTRACTS:Array<String> = Defaults.ABSTRACTS;
    public static var TYPEDEFS:Map<String, Class<Dynamic>> = Defaults.TYPEDEFS;
    public static var VARIABLES:Map<String, Dynamic> = Defaults.VARIABLES;
    
    public static var EXTENSION:String = Defaults.EXTENSION;
    public static var COMPILED_EXTENSION:String = Defaults.COMPILED_EXTENSION;

    public static var SCRIPT_PATH:String = Defaults.SCRIPT_PATH;
    public static var MODULE_PATH:String = Defaults.MODULE_PATH;

    public static var SCRIPT_NAME:String = Defaults.SCRIPT_NAME;

    public static var ERROR_HANDLER:Dynamic -> String -> Void = Defaults.ERROR_HANDLER;
    

    public static function reset()
    {
        FILE_CHECKER = Defaults.FILE_CHECKER;

        CONTENT_READER = Defaults.CONTENT_READER;
        BYTES_READER = Defaults.BYTES_READER;

        BYTES_WRITER = Defaults.BYTES_WRITER;

        IMPORTS = Defaults.IMPORTS;
        ABSTRACTS = Defaults.ABSTRACTS;
        TYPEDEFS = Defaults.TYPEDEFS;
        VARIABLES = Defaults.VARIABLES;

        EXTENSION = Defaults.EXTENSION;
        COMPILED_EXTENSION = Defaults.COMPILED_EXTENSION;

        SCRIPT_PATH = Defaults.SCRIPT_PATH;
        MODULE_PATH = Defaults.MODULE_PATH;

        SCRIPT_NAME = Defaults.SCRIPT_NAME;

        ERROR_HANDLER = Defaults.ERROR_HANDLER;
    }
}