package ale.hscript.interp;

import ale.hscript.macros.TypeListMacro;
import ale.hscript.macros.EnumsMacro;

import ale.hscript.parser.ExprUtil;
import ale.hscript.parser.ExprType;
import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.Config;

import haxe.Constraints.IMap;
import haxe.ds.GenericStack;
import haxe.ds.ObjectMap;
import haxe.io.Path;
import haxe.Log;

class Interp
{
    public final name:String;

    public var imports:Map<String, Class<Dynamic>>;

    public var variables:Scope;

    public var scope:Scope;

    public var softPackage:String;

    final scopePool:GenericStack<Scope>;

    var usings:Array<Dynamic> = [];

    public function new(name:String, ?superInstance:Dynamic)
    {
        this.name = name;

        imports = new Map<String, Class<Dynamic>>();

        variables = scope = new Scope(null, superInstance);

        scopePool = new GenericStack<Scope>();

        for (cls in Config.IMPORTS)
            imports[Type.getClassName(cls).split('.').pop()] = cls;
        
        for (key => val in Config.TYPEDEFS)
            imports[key] = val;

        for (key => val in Config.VARIABLES)
            imports[key] = val;
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

        try
        {
            return switch (expr.type)
            {
                case EEof:
                    null;

                case EPackage(module):
                    softPackage = module;

                    null;

                case EImport(module):
                    imports[module.split('.').pop()] = resolveType(module, false);

                    null;

                case EPackageImport(module):
                    for (type in TypeListMacro.list[module])
                        imports[type] = Type.resolveClass(module + '.' + type);

                    null;

                case EUsing(module):
                    usings.push(eval(module));

                    null;

                case ECast(obj, type):
                    final resObj:Dynamic = eval(obj);

                    if (type == null)
                        resObj;
                    else {
                        final res:Dynamic = Std.downcast(resObj, eval(type));

                        if (res == null && resObj != null)
                            error(EInvalidCast, expr);

                        res;
                    }

                case EVarDecl(id, value, getter, setter, isFinal):
                    scope.define(id, eval(value), getter, setter, isFinal);

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
                        final tryScope:Scope = createScope(scope);

                        tryScope.define(arg.id, e);

                        eval(failed, tryScope);

                        releaseScope(tryScope);
                    }

                    null;

                case ESwitch(obj, cases, defaultExpr):
                    final res:Dynamic = eval(obj);

                    for (cas in cases)
                        if (eval(cas.condition) == res)
                            return eval(cas.body);

                    eval(defaultExpr);

                case EArray(exprs):
                    exprs.map(expr -> eval(expr));

                case EMap(exprs):
                    final res:ObjectMap<Dynamic, Dynamic> = new ObjectMap<Dynamic, Dynamic>();

                    for (key => expr in exprs)
                        res.set(eval(key), eval(expr));

                    res;

                case EStructure(values):
                    final res:Dynamic = {};

                    for (key in values.keys())
                        Reflect.setProperty(res, key, eval(values.get(key)));

                    res;

                case EType(module):
                    resolveType(module);

                case EAssign(obj, value):
                    assign(obj, eval(value));

                case ENew(cls, args):
                    final resolvedClass = switch (cls.type)
                    {
                        case EType(module) if (module == 'Map' || module == 'haxe.ds.Map'):
                            return new Map<Dynamic, Dynamic>();

                        default:
                            eval(cls);
                    };

                    return Type.createInstance(resolvedClass, args.map(arg -> eval(arg)));
                
                case EFunction(arguments, block):
                    Reflect.makeVarArgs((args:Array<Dynamic>) -> {
                        final funcScope:Scope = createScope(scope);

                        for (index => arg in arguments)
                            funcScope.define(arguments[index].id, args[index] ?? eval(arguments[index].value));

                        final res = eval(block, funcScope);

                        releaseScope(funcScope);

                        res;
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

                    final owned = newScope == null;
                    
                    scope = newScope ?? createScope(scope);

                    var res:Dynamic = null;
                    
                    try
                    {
                        for (expr in exprs)
                            res = eval(expr);
                    } catch(e:ReturnSignal) {
                        res = e.value;
                    }

                    if (owned)
                        releaseScope(scope, oldScope);
                    else
                        scope = oldScope;

                    res;

                case EContinue:
                    throw new ContinueSignal();

                case EBreak:
                    throw new BreakSignal();

                case EThrow(val):
                    throw eval(val);

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
                                case 'cast':
                                    return solvedArgs[0];

                                case 'trace':
                                    Log.trace(name + ':'  + expr.line + ': ' + solvedArgs.join(','), null);

                                    return null;

                                default:
                                    null;
                            }
                        
                        case EField(target, id):
                            final obj:Dynamic = eval(target);

                            try
                            {
                                final method:Dynamic = Reflect.getProperty(obj, id);

                                if (method != null)
                                    return Reflect.callMethod(obj, method, solvedArgs);
                            } catch (_:Dynamic) {}

                            for (usingClass in usings)
                            {
                                final method:Dynamic = Reflect.field(usingClass, id);

                                if (method != null)
                                    return Reflect.callMethod(usingClass, method, [obj].concat(solvedArgs));
                            }

                            null;

                        default:
                            Reflect.callMethod(null, eval(object), solvedArgs);
                    }

                case EArrayAccess(obj, key):
                    final res:Dynamic = eval(obj);

                    if (Std.isOfType(res, Array))
                        res[eval(key)];
                    else if (Std.isOfType(res, IMap))
                        cast(res, IMap<Dynamic, Dynamic>).get(eval(key));
                    else {
                        error(EInvalidArrayAccess(Type.getClassName(Type.getClass(res))), expr);
                        
                        null;
                    }

                case EVar(id):
                    try
                    {
                        scope.get(id);
                    } catch(e:ErrorType) {
                        if (imports.exists(id))
                            imports[id];
                        else {
                            error(e, expr);

                            null;
                        }
                    }

                case EFor(indexId, iterId, iter, body):
                    final oldScope:Scope = scope;

                    final newScope:Scope = createScope(scope);
                        
                    if (indexId == null)
                    {
                        final it = makeIterator(eval(iter));

                        while (it.hasNext())
                        {
                            newScope.define(iterId, it.next());

                            try
                            {
                                eval(body, newScope);
                            } catch (c:ContinueSignal) {
                                continue;
                            } catch (b:BreakSignal) {
                                break;
                            }
                        }
                    } else {
                        final it = makeKeyValueIterator(eval(iter));

                        while (it.hasNext())
                        {
                            final pair = it.next();

                            newScope.define(indexId, pair.key);
                            newScope.define(iterId, pair.value);

                            try
                            {
                                eval(body, newScope);
                            } catch (c:ContinueSignal) {
                                continue;
                            } catch (b:BreakSignal) {
                                break;
                            }
                        }
                    }

                    releaseScope(newScope, oldScope);

                    null;

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
                            error(EInvalidOp(op), expr);

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
                            error(EInvalidOp(op), expr);

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

                        case TDoubleQuestion:
                            l ?? eval(right);

                        case TDoubleQuestionEqual:
                            assign(left, l ?? eval(right));

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
                                    error(EInvalidOp(op), expr);
                                    
                                    null;
                            }
                    }

                case ETernOp(condition, ifTrue, ifFalse):
                    eval(condition) ? eval(ifTrue) : eval(ifFalse);

                default:
                    error(EInvalidExpression(expr.type), expr);

                    null;
            }
        } catch(externalError:ErrorType) {
            error(externalError, expr);

            null;
        }
    }

    function resolveType(mod:String, ?allowPackage:Bool = true):Class<Dynamic>
    {
        for (module in [mod, softPackage == null || !allowPackage ? null : softPackage + '.' + mod, mod + EnumsMacro.SUFFIX])
            if (module != null)
                for (method in [
                    () -> imports[module],
                    () -> Type.resolveClass(module)
                ])
                {
                    final res:Class<Dynamic> = method();

                    if (res != null)
                        return res;
                }

        throw ErrorType.ETypeNotFound(mod);

        return null;
    }

    function makeIterator(obj:Dynamic):Iterator<Dynamic>
    {
        #if js
        if (obj is Array)
            return (obj : Array<Dynamic>).iterator();

        if (obj.iterator != null)
            obj = obj.iterator();
        #else
        #if cpp if (obj.iterator != null) #end
            try
            {
                obj = obj.iterator();
            } catch(e:Dynamic) {}
        #end
            
        if (obj.hasNext == null || obj.next == null)
            obj = null;

        return obj;
    }

    function makeKeyValueIterator(obj:Dynamic):KeyValueIterator<Dynamic, Dynamic>
    {
        #if js
        if (obj is Array)
            return (obj : Array<Dynamic>).keyValueIterator();

        if (obj.keyValueIterator != null)
            obj = obj.keyValueIterator();
        #else
        try
        {
            obj = obj.keyValueIterator();
        } catch(e:Dynamic) {}
        #end

        if (obj.hasNext == null || obj.next == null)
            obj = null;

        return obj;
    }

    function assign(obj:Expr, value:Dynamic):Dynamic
        return switch (obj.type)
        {
            case EVar(id):
                scope.set(id, value);

            case EField(obj, id):
                Reflect.setProperty(eval(obj), id, value);

                value;

            case EArrayAccess(obj, key):
                final res:Dynamic = eval(obj);

                if (Std.isOfType(res, Array))
                    res[eval(key)] = value;
                else if (Std.isOfType(res, IMap))
                    cast(res, IMap<Dynamic, Dynamic>).set(eval(key), value);

                value;

            default:
                error(EInvalidAssignment, obj);

                null;
        }

    inline function error(type:ErrorType, expr:Expr)
        throw new Error(type, expr.line, expr.column);

    function createScope(parent:Scope):Scope
    {
        var scope:Scope;

        if (scopePool.isEmpty())
            scope = new Scope();
        else
            scope = scopePool.pop();

        scope.reset(parent);

        return scope;
    }

    function releaseScope(garbageScope:Scope, ?newScope:Scope)
    {
        garbageScope.reset();

        scopePool.add(garbageScope);

        if (newScope != null)
            scope = newScope;
    }
}
