package ale.hscript.parser;

enum ExprType
{
    EVar(id:String, value:Expr);

    EField(object:Null<Expr>, property:String);

    ECall(object:Expr, arguments:Array<Expr>);
    EReturn(value:Expr);

    EFunction(id:String, arguments:Array<FunctionArgument>, block:Expr);

    EBlock(exprs:Array<Expr>);

    EString(str:String);
    ENumber(num:Float);
}