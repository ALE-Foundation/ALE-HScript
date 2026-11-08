package ale.hscript.interp;

import ale.hscript.parser.Expr;

interface IInterp
{
    public function execute(exprs:Array<Expr>):Dynamic;

    public var superInstance:Dynamic;
    public var variables:Scope;
}