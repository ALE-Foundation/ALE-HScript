package ale.hscript.lexer;

enum TokenType
{
    TBool(value:Bool);
    TNumber(value:Float);
    TString(value:String);
    TIdent(value:String);
    
    // Symbols

    TColon;
    TSemiColon;

    TComma;
    TDot;

    TLParen;
    TRParen;

    TLBrace;
    TRBrace;

    TLBracket;
    TRBracket;

    TTripleDot;

    TEqual;

    TQuestionQuestion;

    TOrOr;
    TAndAnd;
    TEqualEqual;
    TNotEqual;

    TGreater;
    TGreaterEqual;
    TLess;
    TLessEqual;

    TMinus;
    TPlus;

    TStar;
    TSlash;
    TPercent;

    TArrow;

    TNot;

    // Keywords

    TFinal;
    TVar;
    TFunction;
    
    TReturn;
    TContinue;
    TBreak;

    TIf;
    TElse;
    TFor;
    TDo;
    TWhile;

    TFalse;
    TTrue;
    TNull;
}