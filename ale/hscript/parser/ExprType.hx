package ale.hscript.parser;

import ale.hscript.lexer.TokenType;

enum ExprType
{
    EVar(id:String, value:Expr);

    EField(object:Null<Expr>, property:String);

    ECall(object:Expr, arguments:Array<Expr>);

    EFunction(id:String, arguments:Array<FunctionArgument>, block:Expr);

    EBlock(exprs:Array<Expr>);

    EString(str:String);
    ENumber(num:Float);
    EArray(members:Array<Expr>);

    EIf(condition:Expr, expr:Expr, ?elseExpr:Expr);
    EWhile(condition:Expr, expr:Expr);
    EDoWhile(condition:Expr, expr:Expr);

    EReturn(value:Expr);
    EContinue;
    EBreak;

    EBinOp(op:TokenType, left:Expr, right:Expr);
    EUnOp(op:TokenType, left:Expr);

    EFalse;
    ETrue;
    ENull;
}