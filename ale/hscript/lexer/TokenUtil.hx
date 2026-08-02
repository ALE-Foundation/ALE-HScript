package ale.hscript.lexer;

@:publicFields
class TokenUtil
{
    static final stringToTokenType:Map<String, TokenType> = [
        'abstract' => TAbstract,
        'break' => TBreak,
        'case' => TCase,
        'cast' => TCast,
        'catch' => TCatch,
        'class' => TClass,
        'continue' => TContinue,
        'do' => TDo,
        'dynamic' => TDynamic,
        'else' => TElse,
        'enum' => TEnum,
        'extends' => TExtends,
        'extern' => TExtern,
        'false' => TFalse,
        'final' => TFinal,
        'for' => TFor,
        'function' => TFunction,
        'if' => TIf,
        'implements' => TImplements,
        'import' => TImport,
        'in' => TIn,
        'inline' => TInline,
        'interface' => TInterface,
        'macro' => TMacro,
        'new' => TNew,
        'null' => TNull,
        'operator' => TOperator,
        'overload' => TOverload,
        'override' => TOverride,
        'package' => TPackage,
        'private' => TPrivate,
        'public' => TPublic,
        'return' => TReturn,
        'static' => TStatic,
        'switch' => TSwitch,
        'this' => TThis,
        'throw' => TThrow,
        'true' => TTrue,
        'try' => TTry,
        'typedef' => TTypedef,
        'untyped' => TUntyped,
        'using' => TUsing,
        'var' => TVar,
        'while' => TWhile
    ];

    static function tokensToTokenTypes(tokens:Array<Token>):Array<TokenType>
        return tokens.map(token -> token.type);
}