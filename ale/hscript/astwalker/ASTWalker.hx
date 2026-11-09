package ale.hscript.astwalker;

import ale.hscript.interp.ControlSignal;
import ale.hscript.interp.*;

import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.Config;

import haxe.ds.GenericStack;

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
                        res = eval(block);
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
                        Config.TRACE(name, expr.line, resArgs);

                        null;
                    
                    default:
                        Reflect.callMethod(null, eval(obj), resArgs);
                }

            case EVar(id):
                resolve(id);

            case EAssign(obj, value):
                assign(obj, eval(value));

            case EString(str):
                str;

            case ENumber(val):
                val;

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
                return scope.set(id, value);

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
}