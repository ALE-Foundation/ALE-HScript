package ale.hscript;

class Config
{
    public static var FILE_CHECKER:String -> Bool = Defaults.FILE_CHECKER;
    public static var FILE_READER:String -> String = Defaults.FILE_READER;
    
    public static final IMPORTS:Array<Class<Dynamic>> = Defaults.IMPORTS;
    public static final ABSTRACTS:Array<String> = Defaults.ABSTRACTS;
    public static final TYPEDEFS:Map<String, Class<Dynamic>> = Defaults.TYPEDEFS;
    public static final VARIABLES:Map<String, Dynamic> = Defaults.VARIABLES;
    
    public static var SCRIPT_EXTENSION:String = Defaults.SCRIPT_EXTENSION;
    public static var SCRIPT_PATH:String = Defaults.SCRIPT_PATH;

    public static var MODULE_EXTENSION:String = Defaults.MODULE_EXTENSION;
    public static var MODULE_PATH:String = Defaults.MODULE_PATH;

    public static var INTERP_NAME:String = Defaults.INTERP_NAME;

    public static var ERROR_HANDLER:String -> Void = Defaults.ERROR_HANDLER;
}