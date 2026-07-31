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

        final res:Expr = switch (cur.type)
        {
            case TVar, TFinal:
                advance();

                final id:String = expectIdent();

                parseOptionalType();

                fastExpr(EVar(id, parseOptionalValue()), cur);

            case TSemiColon:
                advance();

                null;
                
            default:
                parseExpr();
        }

        return res;
    }

    function parseExpr():Expr
    {
        return parsePrimitive();
    }

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TString(str):
                fastAdvanceExpr(EString(str), cur);

            case TNumber(num):
                fastAdvanceExpr(ENumber(num), cur);

            default:
                null;
        }
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
            error(type, token);
        else
            advance();

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

    inline function check(type:TokenType):Bool
        return peek().type == type;
}