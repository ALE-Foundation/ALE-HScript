package ale.hscript.module;

import ale.hscript.lexer.TokenType;

import ale.hscript.interp.Interp;

import ale.hscript.parser.Property;
import ale.hscript.parser.Expr;

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

    override function define(id:String, val:Dynamic, access:Array<TokenType>, getter:Property, setter:Property, isFinal:Bool = false):Void
        if (access != null && access.contains(TStatic))
            scope.define(id, val, getter, setter, isFinal);

    public function exists(id:String):Bool
        return variables.exists(id);

    public function get(id:String):Dynamic
        return variables.get(id);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value);
}