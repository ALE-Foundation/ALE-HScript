package ale.hscript.lexer;

@:publicFields
class TokenUtil
{
    static final stringToTokenType:Map<String, TokenType> = [
        'final' => TFinal
    ];

    static function tokensToTokenTypes(tokens:Array<Token>):Array<TokenType>
        return tokens.map(token -> token.type);
}