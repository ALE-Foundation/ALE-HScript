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

        var requiresSemicolon:Bool = true;

        final res:Expr = switch (cur.type)
        {
            case TFinal, TVar:
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

                fastExpr(EVar(id, parseOptionalValue()), cur);

            case TFunction:
                advance();

                final id:String = switch (advance().type)
                {
                    case TIdent(id):
                        id;

                    default:
                        expectedError(TIdent(null), cur.type);

                        null;
                };

                final arguments:Array<FunctionArgument> = parseFunctionArguments();

                parseOptionalType();

                final isBlock:Bool = peek().type == TLBrace;

                var val:Expr = parseExpr();

                if (isBlock)
                    requiresSemicolon = false;
                else
                    val = fastExpr(EBlock([val]), cur);

                fastExpr(EFunction(id, arguments, val), cur);

            default:
                parseExpr();
        };

        if (requiresSemicolon)
            semicolon();

        return res;
    }

    function parseExpr():Expr
    {
        var res = parsePrimitive();

        while (true)
        {
            switch (peek().type)
            {
                case TDot:
                    advance();

                    res = {
                        type: EField(res, switch (advance().type)
                        {
                            case TIdent(id):
                                id;

                            default:
                                expectedError(TIdent(null), last().type);

                                null;
                        }),
                        pos: res.pos
                    }

                case TLParen:
                    res = {
                        type: ECall(res, parseCallArguments()),
                        pos: res.pos
                    };

                default:
                    break;
            }
        }

        return res;
    }

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TReturn:
                advance();

                fastExpr(EReturn(parseExpr()), cur);

            case TLBrace:
                advance();

                final block:Array<Expr> = [];

                while (peek().type != TRBrace)
                    block.push(parseStatement());

                expect(TRBrace);

                fastExpr(EBlock(block), cur);

            case TIdent(id):
                fastAdvanceExpr(EField(null, id), cur);

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

        while (!end() && peek().type != TRParen)
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

    function parseFunctionArguments():Array<FunctionArgument>
    {
        final result:Array<FunctionArgument> = [];
        
        expect(TLParen);

        while (!end() && peek().type != TRParen)
        {
            final cur:Token = peek();

            final id:String = switch (advance().type)
            {
                case TIdent(id):
                    id;

                default:
                    expectedError(TIdent(null), cur.type);

                    null;
            };

            parseOptionalType();

            result.push({
                id: id,
                value: parseOptionalValue()
            });

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

    function parseOptionalValue():Expr
    {
        if (peek().type == TEqual)
        {
            advance();

            return parseExpr();
        }

        return null;
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

    inline function semicolon():Void
        expect(TSemiColon);

    
    function expect(type:TokenType):Void
        if (peek().type == type)
            advance();
        else
            throw 'Expected ' + type + ', got ' + peek().type;

    inline function expectedError(expected:TokenType, got:TokenType):Void
        throw 'Expected ' + expected + ', got ' + got;
}