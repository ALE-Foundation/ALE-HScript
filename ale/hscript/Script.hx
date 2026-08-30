package ale.hscript;

import ale.hscript.interp.ASTWalker;

import ale.hscript.utils.Util;

import ale.hscript.lexer.*;
import ale.hscript.parser.*;
import ale.hscript.interp.*;

class Script
{
    public final source:String;

    public final interp:Interp;

    public function new(script:String, ?name:String, ?interp:Interp, ?superInstance:Dynamic, ?context:Dynamic)
    {
        final data = Util.resolveScript(script, name);

        source = data.source;

        interp ??= new ASTWalker();
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
        return interp.execute(new Parser(new Lexer(source).tokenize()).parse());

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