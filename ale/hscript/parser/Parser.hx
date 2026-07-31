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
            case EWhile(_, _), EIf(_, _, _), EBlock(_):
                false;

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

            case TWhile:
                advance();

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                fastExpr(EWhile(condition, parseStatement()), cur);

            case TDo:
                advance();

                final expr:Expr = parseStatement();

                expect(TWhile);

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                fastExpr(EDoWhile(condition, expr), cur);

            case TReturn:
                advance();

                fastExpr(EReturn(parseExpr()), cur);

            case TBreak:
                fastAdvanceExpr(EBreak, cur);

            case TContinue:
                fastAdvanceExpr(EContinue, cur);

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

                case TDot:
                    advance();
                    
                    expr = fastExpr(EField(expr, expectIdent()), last());

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
            case TIf:
                advance();

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                final expr:Expr = parseStatement();

                var elseExpr:Expr = null;

                if (!end() && check(TElse))
                {
                    advance();

                    elseExpr = parseStatement();
                }

                fastExpr(EIf(condition, expr, elseExpr), cur);

            case TLBrace:
                advance();

                final exprs:Array<Expr> = [];

                while (!end() && !check(TRBrace))
                    exprs.push(parseStatement());

                expect(TRBrace);

                fastExpr(EBlock(exprs), cur);

            case TLBracket:
                advance();

                final members:Array<Expr> = [];

                while (!end() && !check(TRBracket))
                {
                    members.push(parseExpr());

                    if (check(TComma))
                        advance();
                    else
                        break;
                }

                expect(TRBracket);

                fastExpr(EArray(members), cur);
            
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
            case TLBrace:
                while (!end() && !check(TRBrace))
                {
                    expectIdent();

                    parseOptionalType();

                    if (check(TComma))
                        advance();
                    else
                        break;
                }

                expect(TRBrace);

            case TIdent(_):
                while (!end() && check(TDot))
                {
                    advance();

                    expectIdent();
                }

            case TLParen:
                var count:Int = 0;

                while (!end() && !check(TRParen))
                {
                    if (count > 0 && advance().type != TComma)
                        error(TComma, last());

                    parseType();

                    count++;
                }

                expect(TRParen);

                expect(TArrow);

                parseType();

            default:
                error(null, last());
        }

        switch (peek().type)
        {
            case TLess:
                advance();

                while (!end() && !check(TGreater))
                {
                    parseType();

                    if (check(TComma))
                        advance();
                    else
                        break;
                }

                expect(TGreater);

            case TArrow:
                advance();

                parseType();

            default:
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