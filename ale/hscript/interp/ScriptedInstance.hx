package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedInstance extends Interp
{
    var type:ScriptedClass;

    function toString()
        return type.toString();

    public var methods:Map<String, Dynamic> = [];

    public function new(type:ScriptedClass, body:Array<Expr>, ?args:Array<Dynamic>, ?parent:ScriptedInstance)
    {
        this.type = type;

        super();

        name = type.toString();

        if (parent != null)
            scope = variables = new Scope(parent.variables);

        executeBody(body);

        if (args != null)
            Reflect.callMethod(this, get('new'), args);
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
                                methods[id] = func;
                        }

                    case null:

                    default:
                        throw EInvalidExpression(expr.type);
                }
        });

    public function get(id:String):Dynamic
        return variables.get(id, variables);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value, variables);
}