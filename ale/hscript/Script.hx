package ale.hscript;

import ale.hscript.utils.SourceData;
import ale.hscript.utils.Util;

import ale.hscript.lexer.Lexer;

import ale.hscript.parser.Parser;
import ale.hscript.parser.Expr;

import ale.hscript.interp.Interp;
import ale.hscript.interp.Scope;

class Script
{
    public var data(default, set):SourceData;
    function set_data(val:SourceData)
    {
        if (interp != null)
            interp.name = val.name;

        return data = val;
    }

    public final interp:Interp;

    public function new(script:String, ?name:String, ?interp:Interp, ?context:Scope, ?superInstance:Dynamic)
    {
        interp ??= cast new Interp(superInstance, context);

        this.interp = interp;

        data = Util.resolveSourceData(script, name);
    }

    var safe:Bool = false;

    public function execute(?safe:Bool = true):Dynamic
    {
        this.safe = safe;

        return errorHandled(() -> interp.execute(new Parser(new Lexer(data.source).tokenize()).parse()));
    }

    public function set(id:String, value:Dynamic):Void
        return errorHandled(() -> interp.variables.define(id, value));

    public function get(id:String):Dynamic
        return errorHandled(() -> interp.variables.get(id));
    
    public function call(id:String, ?args:Array<Dynamic>):Dynamic
    {
        if (!interp.variables.exists(id))
            return null;

        return errorHandled(() -> Reflect.callMethod(null, get(id), args ?? []));
    }

    public var failedExecution(default, null):Bool = false;

    function errorHandled<T>(call:Void -> T):T
        try
        {
            return call();
        } catch(error:Dynamic) {
            failedExecution = true;

            if (safe)
                Config.ERROR_HANDLER(data.name, error);
            else
                throw error;

            return null;
        }
}