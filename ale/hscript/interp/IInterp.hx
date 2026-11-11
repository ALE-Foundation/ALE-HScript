package ale.hscript.interp;

import ale.hscript.parser.Expr;

interface IInterp
{
    public function execute(exprs:Array<Expr>):Dynamic;

    public var superInstance:Dynamic;
    public var variables:Scope;

    public var name:String;

    public function eval(expr:Expr, ?ctxt:Bool = true):Dynamic;

    public function scoped<T>(call:Void -> T, ?parent:Scope, ?create:Bool = true):T;
}