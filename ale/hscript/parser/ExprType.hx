package ale.hscript.parser;

enum ExprType
{
    EVar(id:String, value:Expr);

    EField(object:Null<Expr>, property:String);

    ECall(object:Expr, arguments:Array<Expr>);

    EString(id:String);
}