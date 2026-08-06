package ale.hscript.utils;

import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import ale.hscript.parser.Expr;

enum ErrorType
{
    EInvalidCharacter(char:Int);
    EInvalidEscape(char:Int);
    EUnterminatedString;
    EUnterminatedComment;
    EInvalidNumber;

    EExpected(want:TokenType, got:Token);
    EUnexpected(got:Token);
    EUnexpectedEOF;
    EExpectedExpression;
    EExpectedIdentifier;
    EInvalidAssignment(expr:Expr);

    EUndefinedVariable(token:Token);
    EUndefinedField(token:Token);
    ECannotCall(expr:Expr);
    EInvalidOperation(expr:Expr);
}