package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedClass<T>
{
    public final id:String;
    public final body:Array<T>;
    public final scope:Scope<T>;
    public final parent:Dynamic;
    public final implem:Array<ScriptedInterface>;

    public function new(id:String, body:Array<T>, scope:Scope<T>, ?parent:Dynamic, ?implem:Array<ScriptedInterface>)
    {
        this.id = id;
        this.body = body;
        this.scope = scope;
        this.parent = parent;
        this.implem = implem;
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

            for (imp in implem)
                for (field in imp.instance())
                    if (!newScope.exists(field))
                        throw ENeededField(field, imp.id);

            if (args != null)
                Reflect.callMethod(inst, newScope.get('new'), args);
        } catch(e) {
            interp.scope = oldScope;

            throw e;
        }

        interp.scope = oldScope;

        return inst;
    }
}