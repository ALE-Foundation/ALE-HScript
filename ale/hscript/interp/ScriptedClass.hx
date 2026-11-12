package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedClass
{
    public final id:String;
    
    public function toString():String
        return id;

    final body:Array<Expr>;

    final parent:Null<ScriptedClass>;

    public function new(id:String, body:Array<Expr>, ?parent:ScriptedClass)
    {
        this.id = id;
        this.body = body;
        this.parent = parent;
    }

    public function instance(?args:Array<Dynamic>, ?imports:Map<String, Dynamic>):ScriptedInstance
        return new ScriptedInstance(this, body, parent, imports).callConstructor(args);
}