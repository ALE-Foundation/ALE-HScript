package ale.hscript.interp;

import ale.hscript.parser.ExprUtil;
import ale.hscript.parser.ExprType;
import ale.hscript.parser.Expr;
import ale.hscript.Config;

import haxe.Constraints.IMap;
import haxe.io.Path;
import haxe.Log;

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
                } catch(s:ReturnSignal) {
                    throw s;
                } catch(e:Dynamic) {
                    final tryScope:Scope = new Scope(scope);

                    tryScope.define(arg.id, e);

                    eval(failed, tryScope);
                }

                null;

            case EArray(exprs):
                exprs.map(expr -> eval(expr));

            case EMap(exprs):
                final res:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();

                for (expr in exprs.keys())
                    res.set(eval(expr), eval(exprs[expr]));

                res;

            case EStructure(values):
                final res:Dynamic = {};

                for (key in values.keys())
                    Reflect.setProperty(res, key, eval(values.get(key)));

                res;

            case EType(module):
                scope.get(module) ?? Type.resolveClass(module);

            case EAssign(obj, value):
                assign(obj, eval(value));

            case ENew(cls, args):
                final resolvedClass:Dynamic = eval(cls);

                if (resolvedClass == null)
                    switch (cls.type)
                    {
                        case EType(module):
                            switch (module)
                            {
                                case 'Map', 'haxe.ds.Map':
                                    return new Map<Dynamic, Dynamic>();

                                default:
                            }

                        default:
                    }

                return Type.createInstance(resolvedClass, args.map(arg -> eval(arg)));
            
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
                final solvedArgs:Array<Dynamic> = args.map(arg -> eval(arg));

                switch (object.type)
                {
                    case EVar(id):
                        switch (id)
                        {
                            case 'trace':
                                Log.trace(name + ':'  + expr.pos.start.line + ': ' + solvedArgs.join(','), null);

                                return null;

                            default:
                        }

                    default:
                }

                final func:Dynamic = eval(object);

                if (func == null)
                    null;
                else
                    Reflect.callMethod(null, func, solvedArgs);

            case EArrayAccess(obj, key):
                final res:Dynamic = eval(obj);

                if (Std.isOfType(res, Array))
                    res[eval(key)];
                else if (Std.isOfType(res, IMap))
                    cast(res, IMap<Dynamic, Dynamic>).get(eval(key));
                else
                    null;

            case EVar(id):
                scope.get(id);

            case EField(object, id):
                final obj:Dynamic = eval(object);

                if (obj is String && id == 'code')
                    obj.charCodeAt(0);
                else
                    Reflect.getProperty(obj, id);

            case EReturn(value):
                throw new ReturnSignal(eval(value));

            case EFalse:
                false;

            case ETrue:
                true;

            case ENull:
                null;

            case EPrefix(op, right):
                final r:Dynamic = eval(right);

                untyped switch (op)
                {
                    case TTilde:
                        ~r;

                    case TExclamation:
                        !r;

                    case TMinus:
                        -r;

                    case TDoublePlus, TDoubleMinus:
                        assign(right, r + (op == TDoubleMinus ? -1 : 1));

                    default:
                        null;
                }

            case EPostfix(op, left):
                final l:Dynamic = eval(left);

                untyped switch (op)
                {
                    case TDoublePlus, TDoubleMinus:
                        assign(left, l + (op == TDoubleMinus ? -1 : 1));

                        l;

                    default:
                        null;
                }

            case EBinOp(op, left, right):
                final l:Dynamic = eval(left);

                untyped switch (op)
                {
                    case TDoubleAmpersand:
                        l && eval(right);

                    case TDoublePipe:
                        l || eval(right);

                    default:
                        final r:Dynamic = eval(right);
                    
                        untyped switch (op)
                        {
                            case TPercent:
                                l % r;

                            case TPercentEqual:
                                assign(left, l % r);

                            case TStar:
                                l * r;

                            case TStarEqual:
                                assign(left, l * r);

                            case TSlash:
                                l / r;

                            case TSlashEqual:
                                assign(left, l / r);

                            case TPlus:
                                l + r;

                            case TPlusEqual:
                                assign(left, l + r);

                            case TMinus:
                                l - r;

                            case TMinusEqual:
                                assign(left, l - r);

                            case TDoubleLess:
                                Std.int(l) << Std.int(r);

                            case TDoubleLessEqual:
                                assign(left, Std.int(l) << Std.int(r));

                            case TDoubleGreater:
                                Std.int(l) >> Std.int(r);

                            case TDoubleGreaterEqual:
                                assign(left, Std.int(l) >> Std.int(r));

                            case TTripleGreater:
                                Std.int(l) >>> Std.int(r);

                            case TTripleGreaterEqual:
                                assign(left, Std.int(l) >>> Std.int(r));

                            case TAmpersand:
                                Std.int(l) & Std.int(r);

                            case TAmpersandEqual:
                                assign(left, Std.int(l) & Std.int(r));

                            case TPipe:
                                Std.int(l) | Std.int(r);

                            case TPipeEqual:
                                assign(left, Std.int(l) | Std.int(r));

                            case TCaret:
                                Std.int(l) ^ Std.int(r);

                            case TCaretEqual:
                                assign(left, Std.int(l) ^ Std.int(r));

                            case TDoubleEqual:
                                l == r;

                            case TExclamationEqual:
                                l != r;

                            case TLess:
                                l < r;

                            case TLessEqual:
                                l <= r;

                            case TGreater:
                                l > r;

                            case TGreaterEqual:
                                l >= r;

                            case TTripleDot:
                                new IntIterator(l, r);

                            default:
                                null;
                        }
                }

            case ETernOp(condition, ifTrue, ifFalse):
                eval(condition) ? eval(ifTrue) : eval(ifFalse);

            default:
                null;
        }
    }

    function assign(obj:Expr, value:Dynamic):Dynamic
        return switch (obj.type)
        {
            case EVar(id):
                scope.set(id, value);

            case EField(obj, id):
                Reflect.setProperty(eval(obj), id, value);

                value;

            default:
                throw 'Invalid Assignment';

                null;
        }
}
