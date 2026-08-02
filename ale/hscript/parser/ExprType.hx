package ale.hscript.parser;

import ale.hscript.lexer.TokenType;

enum ExprType
{
    EVarDecl(id:String, value:Expr, ?getter:Property, ?setter:Property);
    EFunctionDecl(id:String, value:Expr);

    EVar(id:String);
    EField(object:Null<Expr>, property:String);

    ECall(object:Expr, arguments:Array<Expr>);
    EArrayAccess(object:Expr, key:Expr);

    EFunction(arguments:Array<FunctionArgument>, block:Expr);

    EBlock(exprs:Array<Expr>);

    EString(str:String);
    ENumber(num:Float);
    EArray(members:Array<Expr>);
    EMap(members:Map<Expr, Expr>);

    EAssign(obj:Expr, value:Expr);

    EType(module:String);

    ENew(cls:Expr, args:Array<Expr>);

    ETry(body:Expr, arg:FunctionArgument, failed:Expr);

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