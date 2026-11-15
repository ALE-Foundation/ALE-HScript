package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedClass
{
    public final id:String;
    
    public function toString():String
        return id;

    final body:Array<Expr>;

    final parent:Null<Extensible>;

    final imports:Null<Map<String, Dynamic>>;
    final usings:Null<Array<Dynamic>>;

    public function new(id:String, body:Array<Expr>, ?parent:Extensible, ?imports:Map<String, Dynamic>, ?usings:Array<Dynamic>)
    {
        this.id = id;
        this.body = body;
        this.parent = parent;
        this.imports = imports;
        this.usings = usings;
    }

    public function instance(?args:Array<Dynamic>):Dynamic
        return new ScriptedInstance(this, body, parent, imports, usings).callConstructor(args);
}