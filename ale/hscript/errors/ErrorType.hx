package ale.hscript.errors;

import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import ale.hscript.parser.ExprType;
import ale.hscript.parser.Expr;

enum ErrorType
{
    EInvalidCharacter(char:Int);
    EInvalidEscape(char:Int);
    EUnterminatedString;
    EUnterminatedComment;
    EUnterminatedRegex;
    EInvalidNumber;

    EExpected(want:TokenType, got:TokenType);
    EUnexpected(got:TokenType);

    ETypeNotFound(module:String);
    EInvalidArrayAccess(type:String);
    EInvalidAssignment;
    EInvalidCast;

    EFinalAssign(id:String);
    ENeverWrite(id:String);
    ENeverRead(id:String);
    EUnknownVariable(id:String);

    EInvalidOp(op:TokenType);
    EInvalidExpression(expr:ExprType);
}