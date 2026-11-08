package ale.hscript.errors;

import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import ale.hscript.parser.ExprType;

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

    EMissingSuper;

    EUnsupportedExpression(expr:ExprType);
}