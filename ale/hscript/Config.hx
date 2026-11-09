package ale.hscript;

import ale.hscript.Defaults;

class Config
{
    public static var FILE_CHECKER:String -> Bool = Defaults.FILE_CHECKER;
    public static var CONTENT_READER:String -> String = Defaults.CONTENT_READER;

    public static var IMPORTS:Array<Class<Dynamic>> = Defaults.IMPORTS;
    public static var ABSTRACTS:Array<String> = Defaults.ABSTRACTS;
    public static var TYPEDEFS:Map<String, Class<Dynamic>> = Defaults.TYPEDEFS;
    public static var VARIABLES:Map<String, Dynamic> = Defaults.VARIABLES;
    
    public static var SCRIPT_EXTENSION:String = Defaults.SCRIPT_EXTENSION;
    public static var MODULE_EXTENSION:String = Defaults.MODULE_EXTENSION;

    public static var SCRIPT_PATH:String = Defaults.SCRIPT_PATH;
    public static var MODULE_PATH:String = Defaults.MODULE_PATH;

    public static var SCRIPT_NAME:String = Defaults.SCRIPT_NAME;

    public static var TRACE:String -> Int -> Array<Dynamic> -> Void = Defaults.TRACE;

    public static var ERROR_HANDLER:Dynamic -> String -> Void = Defaults.ERROR_HANDLER;
    
    public static function reset()
    {
        FILE_CHECKER = Defaults.FILE_CHECKER;
        CONTENT_READER = Defaults.CONTENT_READER;

        IMPORTS = Defaults.IMPORTS.copy();
        ABSTRACTS = Defaults.ABSTRACTS.copy();
        TYPEDEFS = Defaults.TYPEDEFS.copy();
        VARIABLES = Defaults.VARIABLES.copy();

        SCRIPT_EXTENSION = Defaults.SCRIPT_EXTENSION;
        MODULE_EXTENSION = Defaults.MODULE_EXTENSION;

        SCRIPT_PATH = Defaults.SCRIPT_PATH;
        MODULE_PATH = Defaults.MODULE_PATH;

        SCRIPT_NAME = Defaults.SCRIPT_NAME;

        TRACE = Defaults.TRACE;

        ERROR_HANDLER = Defaults.ERROR_HANDLER;
    }
}