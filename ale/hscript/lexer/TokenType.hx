package ale.hscript.lexer;

enum TokenType
{
    TBool(value:Bool);
    TNumber(value:Float);
    TString(value:String);
    TIdent(value:String);
    
    // Symbols

    TPlus; // +
    TMinus; // -
    TStar; // *
    TSlash; // /
    TPercent; // %

    TEqual; // =
    TDoubleEqual; // ==
    TExclamationEqual; // !=

    TGreater; // >
    TLess; // <
    TGreaterEqual; // >=
    TLessEqual; // <=

    TAmpersand; // &
    TDoubleAmpersand; // &&

    TPipe; // |
    TDoublePipe; // ||

    TCaret; // ^
    TTilde; // ~
    TExclamation; // !

    TDoubleLess; // <<
    TDoubleGreater; // >>
    TTripleGreater; // >>>

    TPlusEqual; // +=
    TMinusEqual; // -=
    TStarEqual; // *=
    TSlashEqual; // /=
    TPercentEqual; // %=

    TAmpersandEqual; // &=
    TPipeEqual; // |=
    TCaretEqual; // ^=

    TDoubleLessEqual; // <<=
    TDoubleGreaterEqual; // >>=
    TTripleGreaterEqual; // >>>=

    TDoublePlus; // ++
    TDoubleMinus; // --

    TDoubleQuestion; // ??
    TQuestionDot; // ?.

    TArrow; // ->
    TFatArrow; // =>

    TLParen; // (
    TRParen; // )

    TLBrace; // {
    TRBrace; // }

    TLBracket; // [
    TRBracket; // ]

    TDot; // .
    TComma; // ,
    TColon; // :
    TSemicolon; // ;
    TQuestion; // ?

    TAt; // @
    TDollar; // $

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