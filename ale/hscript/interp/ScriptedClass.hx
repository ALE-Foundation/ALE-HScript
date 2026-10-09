package ale.hscript.interp;

import ale.hscript.parser.Expr;

class ScriptedClass
{
    public final name:String;
    public final body:Array<Expr>;
    public final scope:Scope;
    public final parent:Dynamic;

    public function new(name:String, body:Array<Expr>, scope:Scope, ?parent:Dynamic)
    {
        this.name = name;
        this.body = body;
        this.scope = scope;
        this.parent = parent;
    }
}