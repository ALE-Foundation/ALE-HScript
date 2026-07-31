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
            result.push(parseStatement());

        return result;
    }


    function requiresSemicolon(expr:ExprType):Bool
        return switch (expr)
        {
            default:
                true;
        }

    
    function parseStatement():Expr
    {
        final cur:Token = peek();

        final res:Expr = switch (cur.type)
        {
            case TVar, TFinal:
                advance();

                final id:String = expectIdent();

                parseOptionalType();

                fastExpr(EVar(id, parseOptionalValue()), cur);
                
            default:
                parseExpr();
        }

        if (requiresSemicolon(res.type))
            semicolon();

        return res;
    }

    function parseExpr():Expr
    {
        return parsePostfix();
    }

    function parsePostfix():Expr
    {
        var expr:Expr = parsePrefix();

        while (!end())
        {
            switch (peek().type)
            {
                case TLParen:
                    expr = fastExpr(ECall(expr, parseCallArguments()), last());

                default:
                    return expr;
            }
        }

        return expr;
    }

    function parsePrefix():Expr
    {
        return parsePrimitive();
    }

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TIdent(id):
                fastAdvanceExpr(EField(null, id), cur);

            case TString(str):
                fastAdvanceExpr(EString(str), cur);

            case TNumber(num):
                fastAdvanceExpr(ENumber(num), cur);

            case TTrue:
                fastAdvanceExpr(ETrue, cur);

            case TFalse:
                fastAdvanceExpr(EFalse, cur);

            case TNull:
                fastAdvanceExpr(ENull, cur);

            default:
                null;
        }
    }


    function parseCallArguments():Array<Expr>
    {
        final result:Array<Expr> = [];

        expect(TLParen);

        while (!end() && !check(TRParen))
        {
            result.push(parseExpr());

            if (check(TComma))
                advance();
            else
                break;
        }

        expect(TRParen);

        return result;
    }


    function parseOptionalType()
        if (check(TColon))
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
                error(TIdent(null), last());
        }
    }

    function parseOptionalValue():Dynamic
    {
        if (check(TEqual))
        {
            advance();

            return parseExpr();
        }

        return null;
    }


    inline function fastExpr(type:ExprType, token:Token):Expr
        return {
            type: type,
            pos: token.pos
        };

    inline function fastAdvanceExpr(type:ExprType, token:Token):Expr
    {
        advance();

        return fastExpr(type, token);
    }


    inline function semicolon()
        expect(TSemiColon);


    function error(want:TokenType, got:Token)
        throw 'Expected ' + want + ', got ' + (got.type ?? peek().type);


    function expect(type:TokenType, ?token:Token)
        if (check(type))
            advance();
        else
            error(type, token);

    function expectIdent():String
        return switch (advance().type)
        {
            case TIdent(id):
                id;

            default:
                expect(TIdent(null), last());

                null;
        }


    var index:Int = 0;

    inline function advance():Token
        return source[index++];

    inline function peek():Token
        return source[index];

    inline function last():Token
        return source[index - 1];

    inline function next():Token
        return source[index + 1];

    inline function end():Bool
        return index >= length;

    inline function check(type:TokenType):Bool
        return peek().type == type;
}