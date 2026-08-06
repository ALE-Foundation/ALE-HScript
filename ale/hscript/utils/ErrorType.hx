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

    EExpected(want:TokenType, got:TokenType);
    EUnexpected(got:TokenType);
}