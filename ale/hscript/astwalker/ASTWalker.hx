package ale.hscript.astwalker;

import ale.hscript.macros.TypeListMacro;

import ale.hscript.lexer.Lexer;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.parser.Parser;
import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

import haxe.Constraints.IMap;
import haxe.ds.ObjectMap;
import haxe.Log;

class ASTWalker extends Interp<Array<Expr>>
{
    public function executeString(source:String):Dynamic
        return execute(new Parser(new Lexer(source).tokenize()).parse());

    public function execute(?exprs:Array<Expr>):Dynamic
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
        } catch(signal:ControlSignal) {
            return switch (signal)
            {
                case CReturn(value):
                    value;

                default:
                    null;
            }
        }
    }

    function eval(expr:Expr, ?newScope:Scope<Array<Expr>>):Dynamic
    {
        if (expr == null)
            return null;

        try
        {
            return switch (expr.type)
            {
                case EThis:
                    scope.scriptedThis;

                case ESuper:
                    scope.scriptedSuper;

                case EClassDecl(id, body, parent):
                    imports[id] = new ScriptedClass<Array<Expr>>(id, body, scope, eval(parent));

                case ETypedef(_, _):
                    null;

                case EAlias(id, type):
                    imports[id] = eval(type);

                case EEof:
                    null;

                case EPackage(module):
                    softPackage = module;

                    null;

                case EMetadata(_, _):
                    null;

                case EImport(module, alias):
                    imports[alias ?? module.split('.').pop()] = resolveType(module, false);

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
                    } catch (c:ControlSignal) {
                        throw c;
                    } catch(e:Dynamic) {
                        final oldScope = scope;

                        final tryScope = createScope(scope);

                        tryScope.define(arg.id, e);

                        eval(failed, tryScope);
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

                case EArrayComprehension(body):
                    switch (body.type)
                    {
                        case EFor(indexId, iterId, iter, body):
                            evalFor(indexId, iterId, iter, body);

                        case EWhile(condition, body):
                            evalWhile(condition, body);

                        case EDoWhile(condition, body):
                            evalDoWhile(condition, body);

                        default:
                            error(EInvalidExpression(body.type), body);

                            null;
                    }

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
                    final resolvedClass:Dynamic = switch (cls.type)
                    {
                        case EType(module) if (module == 'Map' || module == 'haxe.ds.Map'):
                            return new Map<Dynamic, Dynamic>();

                        default:
                            eval(cls);
                    };

                    final solvedArgs = args.map(arg -> eval(arg));

                    if (resolvedClass is ScriptedClass)
                        return resolvedClass.instance(solvedArgs, this);

                    return Type.createInstance(resolvedClass, solvedArgs);
                
                case EFunction(arguments, block):
                    final capturedScope = scope;

                    Reflect.makeVarArgs((args:Array<Dynamic>) -> {
                        final funcScope = createScope(capturedScope);

                        for (index => arg in arguments)
                            funcScope.define(arguments[index].id, args[index] ?? eval(arguments[index].value));

                        final res = eval(block, funcScope);

                        res;
                    });

                case EIf(condition, expr, elseExpr):
                    if (eval(condition))
                        eval(expr);
                    else if (elseExpr != null)
                        eval(elseExpr);
                    else
                        null;

                case EWhile(condition, body):
                    evalWhile(condition, body);

                    null;

                case EDoWhile(condition, body):
                    evalDoWhile(condition, body);

                    null;

                case EBlock(exprs):
                    final oldScope = scope;
                    
                    scope = newScope ?? createScope(scope);

                    var res:Dynamic = null;
                    
                    try
                    {
                        for (expr in exprs)
                            res = eval(expr);
                    } catch(e:ControlSignal) {
                        switch (e)
                        {
                            case CReturn(value):
                                res = value;

                            default:
                                throw e;
                        }
                    }

                    scope = oldScope;

                    res;

                case EContinue:
                    throw ControlSignal.CContinue;

                case EBreak:
                    throw ControlSignal.CBreak;

                case EThrow(val):
                    throw eval(val);

                case EString(str):
                    str;

                case EInterpolatedString(parts):
                    final buf:StringBuf = new StringBuf();

                    for (part in parts)
                        buf.add(eval(part));

                    buf.toString();

                case ENumber(num):
                    num;

                case ERegex(value):
                    value;

                case ECall(object, args):
                    final solvedArgs:Array<Dynamic> = args.map(arg -> eval(arg));

                    switch (object.type)
                    {
                        case EVar(id) if (id == 'cast'):
                            solvedArgs[0];

                        case EVar(id) if (id == 'trace'):
                            Log.trace(name + ':'  + expr.line + ': ' + solvedArgs.join(','), null);

                            null;

                        case ESuper:
                            final parent = scope.scriptedSuper;

                            if (parent == null)
                                error(EInvalidExpression(expr.type), expr);

                            final constructor = parent.scope.variables.get('new');

                            if (constructor != null)
                                Reflect.callMethod(parent, constructor.value, solvedArgs);

                            null;
                        
                        case EField(target, id):
                            final obj:Dynamic = eval(target);

                            if (obj is ScriptedInstance)
                            {
                                final method = obj.get(id);

                                if (method != null)
                                    return Reflect.callMethod(obj, method, solvedArgs);
                            }

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
                        if (superExists(id))
                            Reflect.getProperty(superInstance, id);
                        else if (imports.exists(id))
                            imports[id];
                        else {
                            throw e;

                            null;
                        }
                    }

                case EFor(indexId, iterId, iter, body):
                    evalFor(indexId, iterId, iter, body);

                    null;

                case EField(object, id):
                    final obj:Dynamic = eval(object);

                    if (obj is String && id == 'code')
                        obj.charCodeAt(0);
                    else if (obj is ScriptedInstance)
                        obj.get(id);
                    else
                        Reflect.getProperty(obj, id);

                case EReturn(value):
                    throw ControlSignal.CReturn(eval(value));

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

                                case TIs:
                                    Std.isOfType(l, r);

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
        } catch (signal:ControlSignal) {
            throw signal;
        } catch(externalError:ErrorType) {
            error(externalError, expr);
        }
    }


    function evalWhile(condition:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        while (eval(condition))
        {
            try
            {
                res.push(eval(body));
            } catch (c:ControlSignal) {
                switch (c)
                {
                    case CBreak:
                        break;

                    case CContinue:
                        continue;

                    default:
                        throw c;
                }
            }
        }

        return res;
    }

    function evalDoWhile(condition:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        do {
            try
            {
                res.push(eval(body));
            } catch (c:ControlSignal) {
                switch (c)
                {
                    case CBreak:
                        break;

                    case CContinue:
                        continue;

                    default:
                        throw c;
                }
            }
        } while(eval(condition));

        return res;
    }

    function evalFor(indexId:String, iterId:String, iter:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        final oldScope = scope;
            
        if (indexId == null)
        {
            final it = makeIterator(eval(iter));

            while (it.hasNext())
            {
                final newScope = createScope(scope);

                newScope.define(iterId, it.next());

                try
                {
                    res.push(eval(body, newScope));
                } catch (c:ControlSignal) {
                    switch (c)
                    {
                        case CBreak:
                            break;

                        case CContinue:
                            continue;

                        default:
                            throw c;
                    }
                }
            }

            scope = oldScope;
        } else {
            final it = makeKeyValueIterator(eval(iter));

            while (it.hasNext())
            {
                final newScope = createScope(scope);

                final pair = it.next();

                newScope.define(indexId, pair.key);
                newScope.define(iterId, pair.value);

                try
                {
                    res.push(eval(body, newScope));
                } catch (c:ControlSignal) {
                    switch (c)
                    {
                        case CBreak:
                            break;

                        case CContinue:
                            continue;

                        default:
                            throw c;
                    }
                }
            }

            scope = oldScope;
        }

        return res;
    }

    function assign(obj:Expr, value:Dynamic):Dynamic
        return switch (obj.type)
        {
            case EVar(id):
                try
                {
                    scope.set(id, value);
                } catch(e:ErrorType) {
                    if (superExists(id))
                    {
                        Reflect.setProperty(superInstance, id, value);

                        value;
                    } else {
                        throw e;

                        null;
                    }
                }

            case EField(obj, id):
                final target = eval(obj);

                if (target is ScriptedInstance)
                    target.set(id, value);
                else
                    Reflect.setProperty(target, id, value);

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
}