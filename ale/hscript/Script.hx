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
    public var data(default, set):SourceData;
    function set_data(val:SourceData)
    {
        if (interp != null)
            interp.name = val.name;

        return data = val;
    }

    public final interp:IInterp;

    public function new(script:String, ?name:String, ?interp:IInterp, ?superInstance:Dynamic, ?context:Dynamic)
    {
        interp ??= cast new ASTWalker();
        interp.superInstance ??= superInstance;

        this.interp = interp;

        data = Util.resolveSourceData(script, name);
    }

    public function execute():Dynamic
        return interp.execute(new Parser(new Lexer(data.source).tokenize()).parse());

    public function set(id:String, value:Dynamic):Void
        errorHandled(() -> interp.variables.define(id, value));

    public function get(id:String):Dynamic
        return errorHandled(() -> interp.variables.get(id));
    
    public function call(id:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!interp.variables.exists(id))
            return null;

        return errorHandled(() -> Reflect.callMethod(null, get(id), args ?? []));
    }

    public var failedExecution(default, null):Bool = false;

    public function safeExecute():Dynamic
        return errorHandled(execute);

    function errorHandled<T>(call:Void -> T):T
        try
        {
            return call();
        } catch(error:Dynamic) {
            failedExecution = true;

            Config.ERROR_HANDLER(data.name, error);

            return null;
        }
}