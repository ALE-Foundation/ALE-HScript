package ale.hscript.module;

import ale.hscript.lexer.TokenType;

import ale.hscript.interp.Interp;

import ale.hscript.parser.Property;
import ale.hscript.parser.Expr;

#if (ALE_HS_MODULES == 'true')
class StaticsInterp extends Interp
{
    public function new(type:ModuleClass, body:Array<Expr>, ?imports:Map<String, Dynamic>, ?usings:Array<Dynamic>)
    {
        super();

        name = type.toString();

        if (imports != null)
            this.imports = imports;

        if (usings != null)
            this.usings = usings;

        execute(body);
    }

    override function execute(exprs:Array<Expr>):Dynamic
        return errorHandled(() -> {
            for (expr in exprs)
                evalStatic(expr);

            return null;
        });

    function evalStatic(expr:Expr):Void
        switch ((lastExpr = expr)?.type)
        {
            case EVarDecl(_, _, access, _, _, _), EFunctionDecl(_, access, _, _) if (access != null && access.contains(TStatic)):
                eval(expr);
            
            default:
        }

    override function define(id:String, val:Dynamic, access:Array<TokenType>, getter:Property, setter:Property, isFinal:Bool = false):Void
        if (access != null && access.contains(TStatic))
            scope.define(id, val, getter, setter, isFinal);

    public function get(id:String):Dynamic
        return variables.get(id);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value);
}
#end