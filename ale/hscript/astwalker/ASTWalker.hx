package ale.hscript.astwalker;

import ale.hscript.interp.*;

import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

class ASTWalker implements IInterp
{
    public var variables:Scope;

    public var superInstance:Dynamic;

    public function new()
        variables = new Scope();

    public function execute(exprs:Array<Expr>):Dynamic
    {
        var result:Dynamic = null;
        
        for (expr in exprs)
            eval(expr);

        return null;
    }

    public function eval(expr:Expr):Dynamic
    {
        switch (expr.type)
        {
            default:
                error(EUnsupportedExpression(expr.type), expr);
        }

        return null;
    }

    inline function error(type:ErrorType, expr:Expr)
        throw new Error(type, expr.line, expr.column);
}