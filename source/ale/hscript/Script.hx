package ale.hscript;

import ale.hscript.lexer.Lexer;
import ale.hscript.parser.Parser;
import ale.hscript.interp.Interp;

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

        interp = new Interp(name ?? (isFile ? path : Config.INTERP_NAME));
    }

    public var lexerTime:Float = 0;
    public var parserTime:Float = 0;
    public var interpTime:Float = 0;

    public function execute():Dynamic
    {
        var result = null;

        var time:Float = Timer.stamp();
        
        final tokens = new Lexer(content).tokenize();

        lexerTime = (Timer.stamp() - time) * 1000;

        time = Timer.stamp();

        final expr = new Parser(tokens).parse();

        parserTime = (Timer.stamp() - time) * 1000;

        time = Timer.stamp();
        
        result = interp.execute(expr);

        interpTime = (Timer.stamp() - time) * 1000;

        return result;
    }

    public function safeExecute():Dynamic
    {
        try
        {
            return execute();
        } catch(error:Exception) {
            Config.ERROR_HANDLER(interp.name + ': ' + error.message);
        }

        return null;
    }
}