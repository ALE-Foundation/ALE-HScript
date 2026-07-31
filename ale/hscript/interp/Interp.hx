package ale.hscript.interp;

import ale.hscript.parser.ExprUtil;
import ale.hscript.parser.Expr;

import ale.hscript.Config;

class Interp
{
    public final name:String;

    public var scope:Scope;

    public function new(name:String)
    {
        this.name = name;

        scope = new Scope();

        for (vrb in Config.VARIABLES.keys())
            scope.define(vrb, Config.VARIABLES[vrb]);
        
        for (tpd in Config.TYPEDEFS.keys())
            scope.define(tpd, Config.TYPEDEFS[tpd]);

        for (cls in Config.IMPORTS)
            scope.define(Type.getClassName(cls).split('.').pop(), cls);
    }

    public function execute(exprs:Array<Expr>):Dynamic
    {
        try
        {
            var result:Dynamic = null;

            for (expr in exprs)
            {
                final res:Dynamic = eval(expr);

                if (res != null)
                    result = res;
            }

            return result;
        } catch(signal:ReturnSignal) {
            return signal.value;
        }
    }

    public function eval(expr:Expr, ?newScope:Scope):Dynamic
    {
        if (expr == null)
            return null;

        return switch (expr.type)
        {
            case EVar(id, value):
                scope.define(id, eval(value));

            case EFunction(id, arguments, block):
                scope.define(id, Reflect.makeVarArgs((args:Array<Dynamic>) -> {
                    var funcScope = new Scope(scope);

                    for (index => arg in arguments)
                        funcScope.define(arguments[index].id, args[index] ?? eval(arguments[index].value));

                    try
                    {
                        eval(block, funcScope);

                        return null;
                    } catch(signal:ReturnSignal) {
                        return signal.value;
                    }
                }));

            case EIf(condition, expr, elseExpr):
                if (eval(condition))
                    eval(expr);
                else if (elseExpr != null)
                    eval(elseExpr);
                else
                    null;

            case EWhile(condition, expr):
                while (eval(condition))
                {
                    try
                    {
                        eval(expr);
                    } catch (c:ContinueSignal) {
                        continue;
                    } catch (b:BreakSignal) {
                        break;
                    }
                }

                null;

            case EDoWhile(condition, expr):
                do {
                    try
                    {
                        eval(expr);
                    } catch (c:ContinueSignal) {
                        continue;
                    } catch (b:BreakSignal) {
                        break;
                    }
                } while(eval(condition));

                null;

            case EBlock(exprs):
                final oldScope:Scope = scope;

                scope = newScope ?? new Scope(scope);

                for (expr in exprs)
                    eval(expr);

                scope = oldScope;

                null;

            case EContinue:
                throw new ContinueSignal();

            case EBreak:
                throw new BreakSignal();

            case EString(str):
                str;

            case ENumber(num):
                num;

            case ECall(object, args):
                Reflect.callMethod(this, eval(object), args.map(arg -> eval(arg)));

            case EField(object, id):
                if (object == null)
                    scope.get(id);
                else
                    Reflect.getProperty(eval(object), id);

            case EReturn(value):
                throw new ReturnSignal(eval(value));

            case EFalse:
                false;

            case ETrue:
                true;

            case ENull:
                null;

            case EBinOp(op, left, right):
                final l:Dynamic = eval(left) ?? 0;
                final r:Dynamic = eval(right) ?? 0;

                untyped switch (op)
                {
                    case TPlus:
                        l + r;

                    case TStar:
                        l * r;

                    case TSlash:
                        l / r;

                    case TPercent:
                        l % r;

                    case TEqualEqual:
                        l == r;

                    case TNotEqual:
                        l != r;

                    case TLess:
                        l < r;

                    case TLessEqual:
                        l <= r;

                    case TGreater:
                        l > r;

                    case TGreaterEqual:
                        l >= r;

                    case TAndAnd:
                        l && r;

                    case TOrOr:
                        l || r;

                    default:
                        null;
                }

            default:
                null;
        }
    }
}
