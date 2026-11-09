package ale.hscript.astwalker;

import ale.hscript.interp.ControlSignal;
import ale.hscript.interp.*;

import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.Config;

import haxe.ds.GenericStack;
import haxe.ds.ObjectMap;

import haxe.Exception;
import haxe.Log;

class ASTWalker implements IInterp
{
    public var variables:Scope;

    public var scope:Scope;

    public var superInstance:Dynamic;

    public var name:String = 'ale-hscript';

    public function new()
    {
        scope = variables = new Scope(null);

        scopeStack = new GenericStack();
    }

    var _lastExpr:Expr;

    public function execute(exprs:Array<Expr>):Dynamic
    {
        var result:Dynamic = null;
        
        try
        {
            for (expr in exprs)
                eval(expr);
        } catch(ctrl:ControlSignal) {
            switch (ctrl)
            {
                case CReturn(val):
                    return val;
                    
                default:
                    error(EInvalidControl(ctrl), _lastExpr);
            }
        } catch(e:ErrorType) {
            error(e, _lastExpr);
        } catch (e:Exception) {
            throw new Exception(_lastExpr.line + ':' + _lastExpr.column + ': ' + e.message);
        }

        return null;
    }

    public function eval(expr:Expr):Dynamic
        return switch ((_lastExpr = expr)?.type)
        {
            case EVarDecl(id, value, access, getter, setter, isFinal):
                scope.define(id, eval(value), getter, setter, isFinal);

                null;

            case EFunctionDecl(id, value, overr, access):
                scope.define(id, eval(value));

                null;

            case EFunction(args, block):
                final curScope:Scope = scope;

                Reflect.makeVarArgs(function (uArgs:Array<Dynamic>)
                {
                    enterScope(curScope);

                    for (i => arg in args)
                        scope.define(arg.id, uArgs[i] ?? eval(arg.value));

                    var res:Dynamic = null;

                    try
                    {
                        eval(block);
                    } catch(ret:ControlSignal) {
                        switch (ret)
                        {
                            case CReturn(val):
                                res = val;

                            default:
                                throw ret;
                        }
                    }

                    exitScope();

                    return res;
                });

            case EBlock(exprs):
                enterScope();

                var res:Dynamic = null;

                for (expr in exprs)
                    res = eval(expr);

                exitScope();

                res;

            case ENull:
                null;

            case ECall(obj, args):
                final resArgs:Array<Dynamic> = evalArray(args);

                switch (obj.type)
                {
                    case EVar(id) if (id == 'trace'):
                        Config.SCRIPT_TRACE(name, expr.line, resArgs);

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

                    for (catchy in catches)
                    {
                        enterScope();

                        try
                        {
                            scope.define(catchy.argument, error);

                            res = eval(catchy.body);

                            exitScope();

                            break;
                        } catch(s:ControlSignal) {
                            exitScope();

                            throw s;
                        } catch(e:Dynamic) {
                            exitScope();

                            error = e;
                        }
                    }

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
                                error(EInvalidOp(token), expr);
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
                        error(EInvalidOp(token), expr);
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
                        error(EInvalidOp(token), expr);
                }

            case EIf(condition, a, b):
                eval(condition) ? eval(a) : eval(b);

            case EString(str):
                str;

            case ENumber(val):
                val;

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

            case EReturn(val):
                throw CReturn(eval(val));

            case EContinue:
                throw CContinue;

            case EBreak:
                throw CBreak;

            case EEof, null:
                null;

            default:
                error(EInvalidExpression(expr.type), expr);
        }

    function assign(obj:Expr, value:Dynamic):Dynamic
        return switch (obj.type)
        {
            case EVar(id):
                scope.set(id, value);

            default:
                null;
        }

    function resolve(id:String)
        return scope.get(id);

    function evalArray(exprs:Array<Expr>):Array<Dynamic>
        return [for (expr in exprs) eval(expr)];

    var scopeStack:GenericStack<Scope>;

    function enterScope(?parent:Scope)
    {
        scopeStack.add(scope);

        scope = new Scope(parent ?? scope);
    }

    function exitScope()
        scope = scopeStack.pop();

    inline function error(type:ErrorType, expr:Expr)
    {
        throw new Error(type, expr.line, expr.column);

        return null;
    }
    
    function evalWhile(condition:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        while (eval(condition))
        {
            enterScope();

            try
            {
                final toPush:Dynamic = eval(body);

                if (toPush != null)
                    res.push(toPush);
            } catch (c:ControlSignal) {
                exitScope();

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

            exitScope();
        }

        return res;
    }

    function evalDoWhile(condition:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        do
        {
            enterScope();

            try
            {
                final toPush:Dynamic = eval(body);

                if (toPush != null)
                    res.push(toPush);
            } catch (c:ControlSignal) {
                exitScope();

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

            exitScope();
        } while (eval(condition));

        return res;
    }

    function evalFor(indexId:String, iterId:String, iter:Expr, body:Expr):Array<Dynamic>
    {
        final res:Array<Dynamic> = [];
        
        final iterator = indexId == null ? makeIterator(eval(iter)) : makeKeyValueIterator(eval(iter));

        while (iterator.hasNext())
        {
            enterScope();

            if (indexId == null)
            {
                scope.define(iterId, iterator.next());
            } else {
                final pair = iterator.next();

                scope.define(indexId, pair.key);
                scope.define(iterId, pair.value);
            }

            try
            {
                final toPush:Dynamic = eval(body);

                if (toPush != null)
                    res.push(toPush);
            } catch (c:ControlSignal) {
                switch (c)
                {
                    case CBreak:
                        exitScope();

                        break;

                    case CContinue:
                        exitScope();
                        
                        continue;

                    default:
                        exitScope();

                        throw c;
                }
            }

            exitScope();
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