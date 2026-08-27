package ale.hscript;

import ale.hscript.lexer.*;
import ale.hscript.parser.*;
import ale.hscript.interp.*;

import ale.hscript.interp.ast.ASTWalker;

class Script
{
    public final content:String;

    public final interp:BaseInterp;

    public function new(script:String, ?name:String, ?interp:BaseInterp, ?superInstance:Dynamic, ?context:Dynamic)
    {
        final path:String = Config.SCRIPT_PATH + script + Config.EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        content = isFile ? Config.FILE_READER(path) : script;

        interp ??= new ASTWalker();
        interp.name ??= (name ?? (isFile ? script : Config.SCRIPT_NAME)) + Config.EXTENSION;
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
        return interp.execute(new Parser(new Lexer(content).tokenize()).parse());

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