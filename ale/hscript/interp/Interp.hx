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

        for (cls in Config.IMPORTS)
            scope.define(Type.getClassName(cls).split('.').pop(), cls);
        
        for (tpd in Config.TYPEDEFS.keys())
            scope.define(tpd, Config.TYPEDEFS[tpd]);

        for (vrb in Config.VARIABLES.keys())
            scope.define(vrb, Config.VARIABLES[vrb]);
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
            case EVarDecl(id, value, getter, setter):
                scope.define(id, eval(value), getter, setter);

                null;
            
            case EFunctionDecl(id, func):
                scope.define(id, eval(func));

                null;

            case ETry(body, arg, failed):
                try
                {
                    eval(body);
                } catch(e:Dynamic) {
                    final tryScope:Scope = new Scope(scope);

                    tryScope.define(arg.id, e);

                    eval(failed, tryScope);
                }

                null;

            case EArray(exprs):
                exprs.map(expr -> eval(expr));

            case EType(module):
                scope.get(module) ?? Type.resolveClass(module);

            case EAssign(obj, value):
                final newVal:Dynamic = eval(value);

                switch (obj.type)
                {
                    case EVar(id):
                        scope.set(id, newVal);

                    case EField(obj, id):
                        Reflect.setProperty(eval(obj), id, newVal);

                        newVal;

                    default:
                        throw 'Invalid Assignment';

                        null;
                }

            case ENew(cls, args):
                Type.createInstance(eval(cls), args.map(arg -> eval(arg)));
            
            case EFunction(arguments, block):
                Reflect.makeVarArgs((args:Array<Dynamic>) -> {
                    final funcScope = new Scope(scope);

                    for (index => arg in arguments)
                        funcScope.define(arguments[index].id, args[index] ?? eval(arguments[index].value));

                    eval(block, funcScope);
                });

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

                var res:Dynamic = null;
                
                try
                {
                    for (expr in exprs)
                        res = eval(expr);
                } catch(e:ReturnSignal) {
                    res = e.value;
                }

                scope = oldScope;

                res;

            case EContinue:
                throw new ContinueSignal();

            case EBreak:
                throw new BreakSignal();

            case EString(str):
                str;

            case ENumber(num):
                num;

            case ECall(object, args):
                Reflect.callMethod(null, eval(object), args.map(arg -> eval(arg)));

            case EVar(id):
                scope.get(id);

            case EField(object, id):
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
