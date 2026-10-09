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

    public function instance(args:Array<Dynamic>, interp:Interp<T>):ScriptedInstance<T>
    {
        final parent:ScriptedClass<T> = cast parent;

        final superInst = parent?.instance(null, interp);

        final newScope = interp.createScope(superInst?.scope ?? scope);

        final inst = new ScriptedInstance<T>(this, newScope);

        newScope.scriptedThis = inst;
        newScope.scriptedSuper = superInst;

        final oldScope = interp.scope;

        interp.scope = newScope;

        try
        {
            for (expr in body)
                interp.eval(expr);

            if (args != null)
                Reflect.callMethod(inst, newScope.variables.get('new').value, args);
        } catch(e) {
            interp.scope = oldScope;

            throw e;
        }

        interp.scope = oldScope;

        return inst;
    }
}