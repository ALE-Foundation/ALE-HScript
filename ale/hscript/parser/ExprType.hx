package ale.hscript.parser;

import ale.hscript.lexer.TokenType;

enum ExprType
{
    EVarDecl(id:String, value:Expr, ?getter:Property, ?setter:Property, ?isFinal:Bool);
    EFunctionDecl(id:String, value:Expr);

    ETypedef(id:String, fields:Array<String>);
    EAlias(id:String, type:Expr);

    
    EVar(id:String);
    EField(object:Expr, property:String);
    EType(module:String);

    EArrayAccess(object:Expr, key:Expr);

    
    ECall(object:Expr, arguments:Array<Expr>);
    ENew(cls:Expr, args:Array<Expr>);

    
    EFunction(arguments:Array<FunctionArgument>, block:Expr);
    EBlock(exprs:Array<Expr>);


    EString(str:String);
    EInterpolatedString(parts:Array<Expr>);
    ENumber(num:Float);

    EArray(members:Array<Expr>);
    EArrayComprehension(expr:Expr);
    EMap(members:Map<Expr, Expr>);
    EStructure(values:Map<String, Expr>);

    ERegex(value:EReg);

    ETrue;
    EFalse;
    ENull;

    
    EAssign(obj:Expr, value:Expr);


    EBinOp(op:TokenType, left:Expr, right:Expr);
    EPrefix(op:TokenType, left:Expr);
    EPostfix(op:TokenType, right:Expr);
    ETernOp(condition:Expr, ifTrue:Expr, ifFalse:Expr);


    EIf(condition:Expr, expr:Expr, ?elseExpr:Expr);

    EWhile(condition:Expr, expr:Expr);
    EDoWhile(condition:Expr, expr:Expr);

    EFor(indexId:String, iterId:String, iter:Expr, body:Expr);

    ESwitch(obj:Expr, cases:Array<SwitchCondition>, ?defaultExpr:Expr);

    ETry(body:Expr, arg:FunctionArgument, failed:Expr);


    EReturn(value:Expr);
    EThrow(value:Expr);

    EContinue;
    EBreak;


    ECast(obj:Expr, ?type:Expr);


    EPackage(module:String);

    EImport(module:String, ?alias:String);
    EPackageImport(module:String);

    EUsing(module:Expr);


    EMetadata(id:String, args:Array<Expr>);

    EEof;
}