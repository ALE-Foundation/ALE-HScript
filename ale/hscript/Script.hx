package ale.hscript;

import ale.hscript.utils.SourceData;
import ale.hscript.utils.Util;

import ale.hscript.lexer.Lexer;

import ale.hscript.parser.Parser;
import ale.hscript.parser.Expr;

import ale.hscript.interp.IInterp;

import ale.hscript.astwalker.ASTWalker;

class Script
{
    public final data:SourceData;

    public final interp:IInterp;

    public function new(script:String, ?name:String, ?interp:IInterp, ?superInstance:Dynamic, ?context:Dynamic)
    {
        data = Util.resolveSourceData(script, name);

        interp ??= cast new ASTWalker();
        interp.superInstance ??= superInstance;

        this.interp = interp;
    }

    public function execute():Dynamic
        return interp.execute(new Parser(new Lexer(data.source).tokenize()).parse());

    public var failedExecution(default, null):Bool = false;

    public function safeExecute():Dynamic
        return errorHandled(execute);

    function errorHandled<T>(call:Void -> T):T
        try
        {
            return call();
        } catch(error:Dynamic) {
            failedExecution = true;

            Config.ERROR_HANDLER(error, data.name);

            return null;
        }
}