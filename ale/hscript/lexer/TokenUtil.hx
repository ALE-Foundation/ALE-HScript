package ale.hscript.lexer;

class TokenUtil
{
    public static final symbolFromString:Map<String, TokenType> = [
        '>' => TGreater,
        '<' => TLess,

        '=' => TEqual,

        '~' => TTilde,

        '(' => TLeftParen,
        ')' => TRightParen,

        '{' => TLeftBrace,
        '}' => TRightBrace,

        '[' => TLeftBracket,
        ']' => TRightBracket,

        '.' => TDot,
        ',' => TComma,
        ':' => TColon,
        ';' => TSemicolon,

        '@' => TAt,
        '$' => TDollar
    ];

    public static final keywordFromString:Map<String, TokenType> = [
        'null' => TNull,
        'true' => TTrue,
        'false' => TFalse,

        'if' => TIf,
        'else' => TElse,
        'for' => TFor,
        'while' => TWhile,
        'do' => TDo,

        'continue' => TContinue,
        'break' => TBreak,
        'return' => TReturn,

        'new' => TNew,

        'var' => TVar,
        'final' => TFinal,
        'function' => TFunction,

        'class' => TClass,
        'enum' => TEnum,
        'typedef' => TTypedef,
        'abstract' => TAbstract,
        'interface' => TInterface,

        'to' => TTo,
        'from' => TFrom,

        'package' => TPackage,
        'import' => TImport,
        'as' => TAs
    ];

    public static final ops:Array<TokenType> = [
        TPlus,
        TMinus,
        TStar,
        TSlash,
        TPercent,

        TEqual,
        TDoubleEqual,
        TNotEqual,
        TExclamationEqual,

        TGreater,
        TLess,
        TGreaterEqual,
        TLessEqual,

        TAmpersand,
        TDoubleAmpersand,

        TPipe,
        TDoublePipe,

        TCaret,
        TTilde,
        TExclamation,

        TDoubleLess,
        TDoubleGreater,
        TTripleGreater,

        TPlusEqual,
        TMinusEqual,
        TStarEqual,
        TSlashEqual,
        TPercentEqual,

        TAmpersandEqual,
        TPipeEqual,
        TCaretEqual,

        TDoubleLessEqual,
        TDoubleGreaterEqual,
        TTripleGreaterEqual,

        TDoublePlus,
        TDoubleMinus,

        TDoubleQuestion,
        TQuestionDot,

        TArrow
    ];

    public static final binOps:Array<TokenType> = [
        TPlus,
        TMinus,
        TStar,
        TSlash,
        TPercent,

        TDoubleEqual,
        TNotEqual,
        TExclamationEqual,

        TGreater,
        TLess,
        TGreaterEqual,
        TLessEqual,

        TAmpersand,
        TDoubleAmpersand,

        TPipe,
        TDoublePipe,

        TCaret,

        TDoubleLess,
        TDoubleGreater,
        TTripleGreater,

        TDoubleQuestion,
        
        TPlusEqual,
        TMinusEqual,
        TStarEqual,
        TSlashEqual,
        TPercentEqual,

        TAmpersandEqual,
        TPipeEqual,
        TCaretEqual,

        TDoubleLessEqual,
        TDoubleGreaterEqual,
        TTripleGreaterEqual
    ];

    public static final assignOps:Array<TokenType> = [
        TPlusEqual,
        TMinusEqual,
        TStarEqual,
        TSlashEqual,
        TPercentEqual,

        TAmpersandEqual,
        TPipeEqual,
        TCaretEqual,

        TDoubleLessEqual,
        TDoubleGreaterEqual,
        TTripleGreaterEqual
    ];
}