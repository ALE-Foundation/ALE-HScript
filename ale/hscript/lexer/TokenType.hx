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
    TQuestion;

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
    TMapArrow;

    TNot;

    // Keywords

    TAbstract;
    TBreak;
    TCase;
    TCast;
    TCatch;
    TClass;
    TContinue;
    TDo;
    TDynamic;
    TElse;
    TEnum;
    TExtends;
    TExtern;
    TFalse;
    TFinal;
    TFor;
    TFunction;
    TIf;
    TImplements;
    TImport;
    TIn;
    TInline;
    TInterface;
    TMacro;
    TNew;
    TNull;
    TOperator;
    TOverload;
    TOverride;
    TPackage;
    TPrivate;
    TPublic;
    TReturn;
    TStatic;
    TSwitch;
    TThis;
    TThrow;
    TTrue;
    TTry;
    TTypedef;
    TUntyped;
    TUsing;
    TVar;
    TWhile;
}