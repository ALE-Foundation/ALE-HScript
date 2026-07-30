package ale.hscript;

import ale.hscript.lexer.*;
import ale.hscript.parser.*;
import ale.hscript.interp.*;

import haxe.Exception;
import haxe.Timer;

class Script
{
    public final content:String;

    public final interp:Interp;

    public function new(?script:String, ?name:String)
    {
        final path:String = Config.SCRIPT_PATH + script + Config.SCRIPT_EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        content = isFile ? Config.FILE_READER(path) : script;

        interp = new Interp(name);
    }

    public function get(id:String)
        return interp.scope.variables.get(id);

    public function call(id:String, ?args:Array<Dynamic>)
    {
        final func:Dynamic = get(id);

        if (func != null)
            return Reflect.callMethod(null, func, args ?? []);

        return null;
    }

    public function execute():Dynamic      
        return interp.execute(new Parser(new Lexer(content).tokenize()).parse());

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