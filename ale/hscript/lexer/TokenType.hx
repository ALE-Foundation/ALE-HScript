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

    TTripleDot;

    // Keywords

    TFinal;
    TVar;
    TFunction;
    TReturn;

    TIf;
    TElse;
    TFor;
    TDo;
    TWhile;

    TFalse;
    TTrue;
}