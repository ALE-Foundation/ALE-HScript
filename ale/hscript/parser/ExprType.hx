package ale.hscript.parser;

enum ExprType
{
    EVar(id:String, value:Expr);

    EString(id:String);
}