package ale.hscript.parser;

import ale.hscript.lexer.TokenUtil;
import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

class Parser
{
    final source:Array<Token>;

    final length:Int;

    public function new(source:Array<Token>)
    {
        this.source = source;

        length = source.length;
    }


    public function parse():Array<Expr>
    {
        final result:Array<Expr> = [];

        while (index < length)
        {
            final res:Expr = parseStatement();

            if (res != null)
                result.push(res);
        }

        return result;
    }

    function parseStatement():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TFinal:
                advance();

                final id:String = switch (advance().type)
                {
                    case TIdent(id):
                        id;

                    default:
                        expectedError(TIdent(null), cur.type);

                        null;
                };

                parseOptionalType();

                var value:Expr = null;

                if (peek().type == TEqual)
                {
                    advance();

                    value = parseExpr();
                }

                fastExpr(EVar(id, value), cur);

            case TSemiColon:
                advance();

                null;

            default:
                null;
        };
    }

    function parseExpr():Expr
        return parsePrimitive();

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TString(str):
                fastAdvanceExpr(EString(str), cur);

            default:
                advance();

                null;
        }
    }

    
    var index:Int = 0;

    inline function peek():Token
        return source[index];

    inline function advance():Token
        return source[index++];

    inline function last():Token
        return source[index - 1];

    inline function check(type:TokenType):Bool
        return peek().type == type;


    inline function fastAdvanceExpr(type:ExprType, token:Token):Expr
    {
        advance();

        return fastExpr(type, token);
    }

    inline function fastExpr(type:ExprType, token:Token):Expr
        return {
            type: type,
            pos: token.pos
        };

    function parseOptionalType()
        if (peek().type == TColon)
        {
            advance();

            parseType();
        }

    function parseType()
    {
        switch (advance().type)
        {
            case TIdent(_):
                switch (peek())
                {
                    default:
                }

            default:
                expect(TIdent(null));
        }
    }

    
    function expect(type:TokenType):Void
        if (peek().type == type)
            advance();
        else
            throw 'Expected ' + type + ', got' + peek();

    inline function expectedError(expected:TokenType, got:TokenType):Void
        throw 'Expected ' + expected + ', got ' + got;
}