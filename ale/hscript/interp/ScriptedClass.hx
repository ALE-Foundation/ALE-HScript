package ale.hscript.interp;

import ale.hscript.parser.Expr;

class ScriptedClass<T>
{
    public final name:String;
    public final body:Array<T>;
    public final scope:Scope<T>;
    public final parent:Dynamic;

    public function new(name:String, body:Array<T>, scope:Scope<T>, ?parent:Dynamic)
    {
        this.name = name;
        this.body = body;
        this.scope = scope;
        this.parent = parent;
    }

    public function instance(args:Array<Dynamic>, interp:Interp<T>)
    {

    }
}