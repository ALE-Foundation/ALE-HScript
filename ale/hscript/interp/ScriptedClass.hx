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

    public function instance(interp:Interp, ?args:Array<Dynamic>):ScriptedInstance
    {
        final superInst:ScriptedInstance = parent?.instance(interp, null);

        final scope:Scope = new Scope(superInst?.variables);

        final inst:ScriptedInstance = new ScriptedInstance(this, scope);

        interp.scoped(() -> {
            for (expr in body)
                if (expr != null)
                {
                    interp.lastExpr = expr;

                    switch (expr.type)
                    {
                        case EFunctionDecl(id, _, _, overr):
                            if (scope.exists(id) && !overr)
                                throw EDuplicated(id);
                            else
                                interp.eval(expr, false);

                        case EVarDecl(id, _, _, _, _, _):
                            if (scope.exists(id))
                                throw EDuplicated(id);
                            else
                                interp.eval(expr, false);

                        default:
                    }
                }

            if (args != null)
                Reflect.callMethod(inst, inst.get('new'), args);
        }, scope, false);

        return inst;
    }
}