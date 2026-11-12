package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedInstance extends Interp
{
    var type:ScriptedClass;

    function toString()
        return methods.exists('toString') ? call('toString') : type.toString();

    public var methods:Map<String, Scope> = [];

    public function new(type:ScriptedClass, body:Array<Expr>, ?args:Array<Dynamic>, ?parent:ScriptedInstance)
    {
        this.type = type;

        super(parent);

        name = type.toString();

        if (parent != null)
        {
            scope = variables = new Scope(parent.variables);

            methods = parent.methods;
        }

        executeBody(body);

        if (args != null)
            Reflect.callMethod(null, get('new'), args);
    }

    public function executeBody(body:Array<Expr>)
        errorHandled(() -> {
            for (expr in body)
                switch ((lastExpr = expr)?.type)
                {
                    case EVarDecl(id, _, _, _, _, _):
                        if (variables.exists(id))
                            throw EDuplicated(id);
                        else
                            eval(expr);

                    case EFunctionDecl(id, access, value, overr):
                        if (methods.exists(id) && !overr)
                        {
                            throw EDuplicated(id);
                        } else {
                            final func:Dynamic = eval(value);

                            define(id, func, access, PDefault, PNever, true);

                            if (id != 'new')
                                methods[id] = scope;
                        }

                    case null:

                    default:
                        throw EInvalidExpression(expr.type);
                }
        });

    override function eval(expr:Expr):Dynamic
        return switch ((lastExpr = expr)?.type)
        {
            case EThis:
                this;

            case ECall(obj, args):
                switch (obj.type)
                {
                    case EVar(id) if (id != 'cast' && id != 'trace'):
                        if (methods.exists(id))
                            call(id, evalArray(args));
                        else
                            throw EUnknownVariable(id);

                        null;

                    default:
                        super.eval(expr);
                }

            default:
                super.eval(expr);
        }

    public function call(id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, methods[id].get(id), args ?? []);

    override function defaultResolve(id:String):Dynamic
        return scope.get(id, methods['get_' + id]);

    override function defaultAssign(id:String, value:Dynamic):Dynamic
        return scope.set(id, value, methods['set_' + id]);

    public function get(id:String):Dynamic
        return variables.get(id, methods['get_' + id]);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value, methods['set_' + id]);
}