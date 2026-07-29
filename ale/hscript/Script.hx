package ale.hscript;

import ale.hscript.lexer.*;
import ale.hscript.parser.*;
import ale.hscript.interp.*;

import haxe.Exception;
import haxe.Timer;

class Script
{
    public final content:String;

    public function new(?script:String, ?name:String)
    {
        final path:String = Config.SCRIPT_PATH + script + Config.SCRIPT_EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        content = isFile ? Config.FILE_READER(path) : script;
    }

    public function execute():Dynamic
    {
        var result = null;

        return result;
    }

    public function safeExecute():Dynamic
    {
        try
        {
            return execute();
        } catch(error:Exception) {
            Config.ERROR_HANDLER(error.message);
        }

        return null;
    }
}