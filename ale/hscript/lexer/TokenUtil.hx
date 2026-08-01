package ale.hscript.lexer;

@:publicFields
class TokenUtil
{
    static final stringToTokenType:Map<String, TokenType> = [
        'final' => TFinal,
        'var' => TVar,
        'function' => TFunction,

        'untyped' => TUntyped,

        'new' => TNew,

        'for' => TFor,
        'if' => TIf,
        'while' => TWhile,
        'do' => TDo,
        'else' => TElse,

        'return' => TReturn,
        'continue' => TContinue,
        'break' => TBreak,

        'false' => TFalse,
        'true' => TTrue,
        'null' => TNull
    ];

    static function tokensToTokenTypes(tokens:Array<Token>):Array<TokenType>
        return tokens.map(token -> token.type);
}