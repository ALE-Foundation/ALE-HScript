package ale.hscript.interp;

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

    public function instance(interp:IInterp, ?args:Array<Dynamic>):ScriptedInstance
    {
        final superInst:ScriptedInstance = parent?.instance(interp, null);

        final scope = new Scope(superInst?.variables);

        final inst:ScriptedInstance = new ScriptedInstance(this, scope);

        interp.scoped(() -> {
            for (expr in body)
                interp.eval(expr, false);

            if (args != null)
                Reflect.callMethod(inst, inst.get('new'), args);
        }, scope, false);

        return inst;
    }
}