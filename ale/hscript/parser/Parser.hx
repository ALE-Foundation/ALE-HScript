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
                parseExpr();
        };
    }

    function parseExpr():Expr
        return parsePrimitive();

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TIdent(id):
                var res:Expr = fastAdvanceExpr(EField(null, id), cur);

                switch (peek().type)
                {
                    case TLParen:
                        res = {
                            type: ECall(res, parseCallArguments()),
                            pos: {
                                start: cur.pos.start,
                                end: last().pos.end ?? last().pos.start
                            }
                        };

                    default:
                }

                res;

            case TString(str):
                fastAdvanceExpr(EString(str), cur);

            case TNumber(num):
                fastAdvanceExpr(ENumber(num), cur);

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

    inline function end():Bool
        return index >= length;


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

            default:
                expect(TIdent(null));
        }
    }

    function parseCallArguments():Array<Expr>
    {
        final result:Array<Expr> = [];

        expect(TLParen);

        while (peek().type != TRParen && !end())
        {
            result.push(parseExpr());

            switch (peek().type)
            {
                case TComma:
                    advance();

                default:
                    break;
            }
        }

        expect(TRParen);

        return result;
    }
    

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

    
    function expect(type:TokenType):Void
        if (peek().type == type)
            advance();
        else
            throw 'Expected ' + type + ', got ' + peek().type;

    inline function expectedError(expected:TokenType, got:TokenType):Void
        throw 'Expected ' + expected + ', got ' + got;
}