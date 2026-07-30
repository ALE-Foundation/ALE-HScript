package ale.hscript.lexer;

enum TokenType
{
    TBool(value:Bool);
    TNumber(value:Float);
    TString(value:String);
    TIdent(value:String);
    
    // Symbols

    TEqual;

    TColon;
    TSemiColon;

    TLParen;
    TRParen;

    TComma;
    TDot;

    TLBrace;
    TRBrace;

    // Keywords

    TFinal;
    TVar;
    TFunction;
    TReturn;
}