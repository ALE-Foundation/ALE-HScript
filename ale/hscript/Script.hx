package ale.hscript;

import ale.hscript.utils.Util;

import ale.hscript.lexer.Lexer;

import ale.hscript.parser.Parser;
import ale.hscript.parser.Expr;

import ale.hscript.interp.Interp;

import ale.hscript.astwalker.ASTWalker;

class Script<T = Array<Expr>>
{
    public final source:String;

    public final interp:Interp<T>;

    public function new(script:String, ?name:String, ?interp:Interp<T>, ?superInstance:Dynamic, ?context:Dynamic)
    {
        final data = Util.resolveSourceData(script, name);

        source = data.source;

        interp ??= cast new ASTWalker();
        interp.name ??= data.name;
        interp.superInstance ??= superInstance;

        this.interp = interp;
    }

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

    public function execute():Dynamic
        return interp.executeString(source);

    public var failedExecution(default, null):Bool = false;

    public function safeExecute():Dynamic
        return errorHandled(() -> execute());

    function errorHandled<T>(call:Void -> T):T
        try
        {
            return call();
        } catch(error:Dynamic) {
            failedExecution = true;

            Config.ERROR_HANDLER(error, interp.name);

            return null;
        }
}