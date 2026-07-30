package ale.hscript.interp;

import ale.hscript.parser.Expr;

import haxe.Log;

class Interp
{
    public final name:String;

    public var scope:Scope;

    public function new(name:String)
    {
        this.name = name;

        scope = new Scope();

        scope.define('trace', Reflect.makeVarArgs((args:Array<Dynamic>) -> Log.trace(args.join(', '), null)));
    }

    public function execute(exprs:Array<Expr>):Dynamic
    {
        try
        {
            var result:Dynamic = null;

            for (expr in exprs)
            {
                final res:Dynamic = executeExpr(expr);

                if (res != null)
                    result = res;
            }

            return result;
        } catch(signal:ReturnSignal) {
            return signal.value;
        }
    }

    public function executeExpr(expr:Expr, ?newScope:Scope):Dynamic
    {
        return switch (expr.type)
        {
            case EVar(id, value):
                scope.define(id, executeExpr(value));

            case EFunction(id, arguments, block):
                scope.define(id, Reflect.makeVarArgs((args:Array<Dynamic>) -> {
                    var funcScope = new Scope(scope);

                    for (index => arg in arguments)
                        funcScope.define(arguments[index].id, args[index] ?? executeExpr(arguments[index].value));

                    try
                    {
                        executeExpr(block, funcScope);

                        return null;
                    } catch(signal:ReturnSignal) {
                        return signal.value;
                    }
                }));

            case EBlock(exprs):
                final oldScope:Scope = scope;

                scope = newScope ?? new Scope(scope);

                for (expr in exprs)
                    executeExpr(expr);

                scope = oldScope;

                null;

            case EString(str):
                str;

            case ENumber(num):
                num;

            case ECall(object, args):
                Reflect.callMethod(null, executeExpr(object), args.map(arg -> executeExpr(arg)));

            case EField(object, id):
                if (object == null)
                    scope.get(id);
                else
                    Reflect.getProperty(executeExpr(object), id);

            case EReturn(value):
                throw new ReturnSignal(executeExpr(value));

            case EFalse:
                false;

            case ETrue:
                true;

            default:
                null;
        }
    }
}