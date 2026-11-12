package ale.hscript.interp;

import ale.hscript.interp.ControlSignal;

import ale.hscript.lexer.TokenType;

import ale.hscript.parser.Property;
import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.Config;

import ale.hscript.macros.AbstractsMacro;
import ale.hscript.macros.TypeListMacro;
import ale.hscript.macros.EnumsMacro;

import haxe.ds.GenericStack;
import haxe.ds.ObjectMap;

import haxe.Constraints.IMap;
import haxe.Exception;
import haxe.Log;

class Interp
{
    public var variables:Scope;

    public var scope:Scope;

    public var superInstance:Dynamic;

    public var name:String = 'ale-hscript';

    public var context:Scope;

    var imports:Map<String, Dynamic>;

    public function new(?superInstance:Dynamic, ?context:Scope)
    {
        this.superInstance = superInstance;
        this.context = context;

        scope = variables = new Scope(null);

        imports = new Map();

        usings = [];

        for (cls in Config.IMPORTS)
            imports[Type.getClassName(cls).split('.').pop()] = cls;

        for (abs in Config.ABSTRACTS)
            imports[abs.split('.').pop()] = Type.resolveClass(abs + AbstractsMacro.SUFFIX);

        for (enu in Config.ENUMS)
            imports[enu.split('.').pop()] = Type.resolveClass(enu + EnumsMacro.SUFFIX);

        for (key => cls in Config.TYPEDEFS)
            imports[key] = cls;

        for (key => val in Config.VARIABLES)
            scope.define(key, val);

        scopeStack = new GenericStack();
    }

    var lastExpr:Expr;

    inline function error(type:ErrorType, expr:Expr)
    {
        throw new Error(type, expr.line, expr.column);

        return null;
    }

    function errorHandled<Dynamic>(call:Void -> Dynamic):Dynamic
        return try
        {
            call();
        } catch(e:Error) {
            throw e;
        } catch(e:ErrorType) {
            error(e, lastExpr);
        } catch (e:Exception) {
            throw new Exception(lastExpr.line + ':' + lastExpr.column + ': ' + e.message);
        } catch(ctrl:ControlSignal) {
            switch (ctrl)
            {
                case CReturn(val):
                    return val;

                default:
                    error(EInvalidControl(ctrl), lastExpr);
            }
        }

    public function execute(exprs:Array<Expr>):Dynamic
        return errorHandled(() -> {
            for (expr in exprs)
                eval(expr);

            return null;
        });

    var _package:String;
    var usings:Array<Dynamic>;

    public function eval(expr:Expr):Dynamic
        return switch ((lastExpr = expr)?.type)
        {
            case ESuperFieldCall(id, args):
                Reflect.callMethod(null, resolveField(superInstance, id), evalArray(args));

            case EClassDecl(id, body, parent, implem):
                imports[id] = new ScriptedClass(id, body, eval(parent));

                null;

            case EPackage(module):
                _package = module;

                null;

            case EImport(module, alias):
                imports[alias ?? module.split('.').pop()] = resolveClass(module);

                null;

            case EPackageImport(module):
                for (type in TypeListMacro.list[module])
                    imports[type] = resolveClass(module + '.' + type);

                null;

            case EUsing(module):
                usings.unshift(eval(module));

                null;

            case ETypedef(_, _):
                null;

            case EAlias(id, type):
                imports[id] = eval(type);

            case EField(obj, id):
                resolveField(eval(obj), id);

            case ESafeField(obj, id):
                final res:Dynamic = eval(obj);

                res == null ? null : resolveField(res, id);

            case EArrayAccess(obj, key):
                final res:Dynamic = eval(obj);

                if (Std.isOfType(res, Array))
                    res[eval(key)];
                else if (Std.isOfType(res, IMap))
                    cast(res, IMap<Dynamic, Dynamic>).get(eval(key));
                else {
                    throw EInvalidArrayAccess(Type.getClassName(Type.getClass(res)));
                    
                    null;
                }

            case ENew(type, args):
                createInstance(eval(type), evalArray(args));

            case EInterpolatedString(parts):
                final buf:StringBuf = new StringBuf();

                for (part in parts)
                    buf.add(eval(part));

                buf.toString();

            case EVarDecl(id, value, access, getter, setter, isFinal):
                define(id, eval(value), access, getter, setter, isFinal);

                null;

            case EFunctionDecl(id, access, value, _):
                define(id, eval(value), access, PDefault, PNever, true);

                null;

            case EFunction(args, block, lambda):
                final curScope:Scope = scope;

                Reflect.makeVarArgs(function(uArgs:Array<Dynamic>)
                {
                    return scoped(() -> {
                        for (i => arg in args)
                            scope.define(arg.id, uArgs[i] ?? eval(arg.value));

                        var res:Dynamic = null;

                        try
                        {
                            res = eval(block);
                        } catch(ret:ControlSignal) {
                            switch (ret)
                            {
                                case CReturn(val):
                                    return val;

                                default:
                                    throw ret;
                            }
                        }

                        return res;
                    }, curScope);
                });

            case EBlock(exprs):
                scoped(() -> {
                    var res:Dynamic = null;

                    for (expr in exprs)
                        res = eval(expr);

                    return res;
                });

            case ENull:
                null;

            case ECall(obj, args):
                final resArgs:Array<Dynamic> = evalArray(args);

                switch (obj.type)
                {
                    case EVar(id) if (id == 'cast'):
                        resArgs[0];

                    case EVar(id) if (id == 'trace'):
                        Config.SCRIPT_TRACE(name, expr.line, resArgs);

                        null;

                    case ESafeField(target, id):
                        final obj:Dynamic = eval(target);

                        if (obj == null)
                        {
                            null;
                        } else if (obj is ScriptedInstance) {
                            if (obj.methods.exists(id))
                                obj.call(id, resArgs);
                            else
                                null;
                        } else {
                            final method:Dynamic = resolveField(obj, id);

                            if (method == null)
                                null;
                            else
                                Reflect.callMethod(obj, method, resArgs);
                        }

                    case EField(target, id):
                        final obj:Dynamic = eval(target);

                        if (obj is ScriptedInstance)
                        {
                            return obj.call(id, resArgs);
                        } else {
                            try
                            {
                                final method:Dynamic = resolveField(obj, id);

                                if (method != null)
                                    return Reflect.callMethod(obj, method, resArgs);
                            } catch (_:Dynamic) {}

                            for (usingClass in usings)
                            {
                                final method:Dynamic = Reflect.field(usingClass, id);

                                if (method != null)
                                    return Reflect.callMethod(usingClass, method, [obj].concat(resArgs));
                            }
                        }

                        null;
                    
                    default:
                        Reflect.callMethod(null, eval(obj), resArgs);
                }

            case EVar(id):
                resolve(id);

            case EAssign(obj, value):
                assign(obj, eval(value));

            case EFor(indexId, iterId, iter, body):
                evalFor(indexId, iterId, iter, body);

            case EWhile(condition, expr):
                evalWhile(condition, expr);

            case EDoWhile(condition, expr):
                evalDoWhile(condition, expr);

            case ESwitch(val, cases, defaultExpr):
                final key:Dynamic = eval(val);

                for (cas in cases)
                    for (condition in cas.conditions)
                        if (eval(condition) == key)
                            return eval(cas.body);

                eval(defaultExpr);

            case EArrayComprehension(expr):
                eval(expr);

            case ETry(body, catches):
                try
                {
                    eval(body);
                } catch(s:ControlSignal) {
                    throw s;
                } catch(e:Dynamic) {
                    var res:Dynamic = null;

                    var error:Dynamic = e;

                    var handled:Bool = false;

                    for (catchy in catches)
                    {
                        try
                        {
                            res = scoped(() -> {
                                scope.define(catchy.argument, error);

                                return eval(catchy.body);
                            });

                            handled = true;

                            break;
                        } catch(s:ControlSignal) {
                            throw s;
                        } catch(e:Dynamic) {
                            error = e;
                        }
                    }

                    if (!handled)
                        throw error;

                    res;
                }

            case EThrow(val):
                throw eval(val);

            case EBinOp(token, a, b):
                switch (token)
                {
                    case TDoubleAmpersand:
                        eval(a) && eval(b);

                    case TDoublePipe:
                        eval(a) || eval(b);

                    case TDoubleQuestion:
                        eval(a) ?? eval(b);
                    
                    case TDoubleQuestionEqual:
                        eval(a) ?? assign(a, eval(b));

                    default:
                        final l:Dynamic = eval(a);
                        final r:Dynamic = eval(b);

                        switch (token)
                        {
                            case TIs:
                                isOfType(l, r);

                            case TTripleDot:
                                new IntIterator(l, r);

                            case TDoubleEqual:
                                l == r;

                            case TExclamationEqual:
                                l != r;

                            case TLess:
                                l < r;

                            case TGreater:
                                l > r;

                            case TLessEqual:
                                l <= r;

                            case TGreaterEqual:
                                l >= r;

                            case TPercent:
                                l % r;

                            case TStar:
                                l * r;

                            case TSlash:
                                l / r;

                            case TPlus:
                                l + r;

                            case TMinus:
                                l - r;

                            case TDoubleLess:
                                Std.int(l) << Std.int(r);

                            case TDoubleGreater:
                                Std.int(l) >> Std.int(r);

                            case TTripleGreater:
                                Std.int(l) >>> Std.int(r);

                            case TAmpersand:
                                Std.int(l) & Std.int(r);

                            case TPipe:
                                Std.int(l) | Std.int(r);

                            case TCaret:
                                Std.int(l) ^ Std.int(r);

                            case TPercentEqual:
                                assign(a, l % r);

                            case TStarEqual:
                                assign(a, l * r);

                            case TSlashEqual:
                                assign(a, l / r);

                            case TPlusEqual:
                                assign(a, l + r);

                            case TMinusEqual:
                                assign(a, l - r);

                            case TDoubleLessEqual:
                                assign(a, Std.int(l) << Std.int(r));

                            case TDoubleGreaterEqual:
                                assign(a, Std.int(l) >> Std.int(r));

                            case TTripleGreaterEqual:
                                assign(a, Std.int(l) >>> Std.int(r));

                            case TAmpersandEqual:
                                assign(a, Std.int(l) & Std.int(r));

                            case TPipeEqual:
                                assign(a, Std.int(l) | Std.int(r));

                            case TCaretEqual:
                                assign(a, Std.int(l) ^ Std.int(r));

                            default:
                                throw EInvalidOp(token);
                        }
                }

            case EPrefix(token, a):
                final l:Dynamic = eval(a);

                switch (token)
                {
                    case TTilde:
                        ~l;

                    case TExclamation:
                        !l;

                    case TMinus:
                        -l;

                    case TDoublePlus:
                        assign(a, l + 1);

                    case TDoubleMinus:
                        assign(a, l - 1);

                    default:
                        throw EInvalidOp(token);
                }

            case EPostfix(token, a):
                final l:Dynamic = eval(a);

                switch (token)
                {
                    case TDoublePlus:
                        assign(a, l + 1);

                        l;

                    case TDoubleMinus:
                        assign(a, l - 1);

                        l;

                    default:
                        throw EInvalidOp(token);
                }

            case EIf(condition, a, b):
                eval(condition) ? eval(a) : eval(b);

            case EString(str):
                str;

            case ENumber(val):
                val;

            case EMetadata(_, _):
                null;

            case ERegex(reg):
                reg;

            case EFalse:
                false;

            case ETrue:
                true;

            case EArray(exprs):
                evalArray(exprs);

            case EMap(members):
                final res = new ObjectMap();

                for (key => val in members)
                    res.set(eval(key), eval(val));

                res;

            case EStructure(values):
                final res:Dynamic = {};

                for (key => val in values)
                    assignField(res, key, eval(val));

                res;

            case ECast(obj, type):
                final resObj:Dynamic = eval(obj);

                if (type == null)
                    resObj;
                else {
                    final res:Dynamic = Std.downcast(resObj, eval(type));

                    if (res == null && resObj != null)
                        throw EInvalidCast;

                    res;
                }

            case EType(id):
                resolveType(id);

            case EReturn(val):
                throw CReturn(eval(val));

            case EContinue:
                throw CContinue;

            case EBreak:
                throw CBreak;

            case EEof, null:
                null;

            default:
                throw EInvalidExpression(expr.type);
        }

    function define(id:String, val:Dynamic, access:Array<TokenType>, getter:Property, setter:Property, isFinal:Bool = false):Void
        if (context != null && access != null)
        {
            if (access.contains(TPublic))
                context.define(id, val, getter, setter, isFinal);
            else
                scope.define(id, val, getter, setter, isFinal);
        } else {
            scope.define(id, val, getter, setter, isFinal);
        }

    function defaultAssign(id:String, value:Dynamic):Dynamic
        return scope.set(id, value);

    function assign(obj:Expr, value:Dynamic):Dynamic
        return switch (obj.type)
        {
            case EVar(id):
                try
                {
                    defaultAssign(id, value);
                } catch(e:ErrorType) {
                    var done:Bool = false;

                    var res = null;
                    
                    if (context != null)
                        try
                        {
                            res = context.set(id, value);

                            done = true;
                        } catch(_) {}

                    if (!done)
                        if (superInstance == null)
                            throw e;
                        else {
                            assignField(superInstance, id, value);

                            res = value;
                        }

                    res;
                }

            case EArrayAccess(arr, key):
                final id:Dynamic = eval(key);
                final res:Dynamic = eval(arr);

                if (Std.isOfType(res, Array))
                    res[id] = value;
                else if (Std.isOfType(res, IMap))
                    cast(res, IMap<Dynamic, Dynamic>).set(id, value);
                else
                    throw EInvalidArrayAccess(Type.getClassName(Type.getClass(res)));

                value;

            case EField(obj, id):
                assignField(eval(obj), id, value);

            default:
                throw EInvalidAssignment;
        }

    function defaultResolve(id:String):Dynamic
        return scope.get(id);

    function resolve(id:String)
        return try
        {
            defaultResolve(id);
        } catch(e:ErrorType) {
            switch (e)
            {
                case EUnknownVariable(_):
                    var done:Bool = false;

                    var res = null;

                    if (context != null)
                        try
                        {
                            res = context.get(id);

                            done = true;
                        } catch(_) {}

                    if (done)
                        return res;
                    
                    res ??= imports[id];

                    if (res == null && superInstance != null)
                        res = Reflect.getProperty(superInstance, id);

                    if (res == null)
                        throw e;

                    res;

                default:
                    throw e;

                    null;
            }
        }

    function isOfType(obj:Dynamic, type:Dynamic):Bool
        return Std.isOfType(obj, type);

    function resolveClass(module:String):Dynamic
    {
        var res:Dynamic = null;
        
        for (mod in [module, module + EnumsMacro.SUFFIX, module + AbstractsMacro.SUFFIX])
            if ((res = Type.resolveClass(mod)) != null)
                break;

        res ??= TypeListMacro.typedefs[module];

        if (res == null)
            throw ETypeNotFound(module);

        return res;
    }

    function resolveType(module:String):Dynamic
    {
        var res:Dynamic = imports[module];

        try
        {
            res ??= resolveClass(module);
        } catch(e:ErrorType) {}

        if (res == null)
            throw ETypeNotFound(module);

        return res;
    }

    function resolveField(obj:Dynamic, id:String):Dynamic
        return obj is ScriptedInstance ? obj.get(id) : Reflect.getProperty(obj, id);

    function assignField(obj:Dynamic, id:String, value:Dynamic):Dynamic
        return if (obj is ScriptedInstance)
        {
            obj.set(id, value);
        } else {
            Reflect.setProperty(obj, id, value);

            value;
        }

    function createInstance(obj:Dynamic, ?args:Array<Dynamic>):Dynamic
    {
        return obj is ScriptedClass ? obj.instance(args, imports) : Type.createInstance(obj, args ?? []);
    }

    function evalArray(exprs:Array<Expr>):Array<Dynamic>
        return [for (expr in exprs) eval(expr)];


    var scopeStack:GenericStack<Scope>;

    function enterScope(?parent:Scope, ?create:Bool = true):Void
    {
        scopeStack.add(scope);

        scope = parent != null && !create ? parent : new Scope(parent ?? scope);
    }

    function exitScope():Void
        scope = scopeStack.pop();

    function scoped<T>(call:Void -> T, ?parent:Scope, ?create:Bool = true):T
    {
        enterScope(parent, create);

        try
        {
            final res:T = call();

            exitScope();

            return res;
        }
        catch (e:Dynamic)
        {
            exitScope();
            
            throw e;
        }
    }

    function evalWhile(condition:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        while (eval(condition))
        {
            try
            {
                final toPush:Dynamic = eval(body);

                if (toPush != null)
                    res.push(toPush);
            } catch(c:ControlSignal) {
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

        do
        {
            try
            {
                final toPush:Dynamic = eval(body);

                if (toPush != null)
                    res.push(toPush);
            } catch(c:ControlSignal) {
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
        } while (eval(condition));

        return res;
    }

    function evalFor(indexId:String, iterId:String, iter:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        final iterator = indexId == null ? makeIterator(eval(iter)) : makeKeyValueIterator(eval(iter));

        while (iterator.hasNext())
        {
            try
            {
                final toPush:Dynamic = scoped(() -> {
                    if (indexId == null)
                    {
                        scope.define(iterId, iterator.next());
                    } else {
                        final pair = iterator.next();

                        scope.define(indexId, pair.key);
                        scope.define(iterId, pair.value);
                    }

                    return eval(body);
                });

                if (toPush != null)
                    res.push(toPush);
            } catch(c:ControlSignal) {
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
}