package ale.hscript.lexer;

@:publicFields
class TokenUtil
{
    static final stringToTokenType:Map<String, TokenType> = [
        'final' => TFinal,
        'var' => TVar,
        'function' => TFunction,
        'return' => TReturn,

        'for' => TFor,
        'if' => TIf,
        'while' => TWhile,
        'do' => TDo,
        'else' => TElse,

        'false' => TFalse,
        'true' => TTrue
    ];

    static function tokensToTokenTypes(tokens:Array<Token>):Array<TokenType>
        return tokens.map(token -> token.type);
}