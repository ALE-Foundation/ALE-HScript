package ale.hscript.lexer;

enum TokenType
{
    TIdent(id:String);
    
    // Literals

    TString(str:String);
    TNumber(num:Float);
        
    // Symbol

    TPlus;
    TMinus;
    TStar;
    TSlash;
    TPercent;

    TEqual;
    TDoubleEqual;
    TNotEqual;
    TExclamationEqual;

    TGreater;
    TLess;
    TGreaterEqual;
    TLessEqual;

    TAmpersand;
    TDoubleAmpersand;

    TPipe;
    TDoublePipe;

    TCaret;
    TTilde;
    TExclamation;

    TDoubleLess;
    TDoubleGreater;
    TTripleGreater;

    TPlusEqual;
    TMinusEqual;
    TStarEqual;
    TSlashEqual;
    TPercentEqual;

    TAmpersandEqual;
    TPipeEqual;
    TCaretEqual;

    TDoubleLessEqual;
    TDoubleGreaterEqual;
    TTripleGreaterEqual;

    TDoublePlus;
    TDoubleMinus;

    TDoubleQuestion;
    TQuestionDot;

    TArrow;
    TMapArrow;

    TLeftParen;
    TRightParen;

    TLeftBrace;
    TRightBrace;

    TLeftBracket;
    TRightBracket;

    TDot;
    TComma;
    TColon;
    TSemicolon;
    TQuestion;

    TAt;
    TDollar;

    // Keywords

    TNull;
    TTrue;
    TFalse;

    TIf;
    TElse;
    TFor;
    TWhile;
    TDo;

    TContinue;
    TBreak;
    TReturn;
    
    TNew;

    TVar;
    TFinal;
    TFunction;

    TClass;
    TEnum;
    TTypedef;
    TAbstract;
    TInterface;

    TTo;
    TFrom;

    TPackage;
    TImport;
    TAs;
}