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

        trace(TokenUtil.tokensToTokenTypes(source));

        setPrecedenceLevel(TEqual);

        setPrecedenceLevel(TQuestionQuestion);
        setPrecedenceLevel(TOrOr);

        setPrecedenceLevel(TAndAnd);

        setPrecedenceLevel(TEqualEqual);
        setPrecedenceLevel(TNotEqual, true);

        setPrecedenceLevel(TLess);
        setPrecedenceLevel(TLessEqual, true);
        setPrecedenceLevel(TGreater, true);
        setPrecedenceLevel(TGreaterEqual, true);

        setPrecedenceLevel(TPlus);
        setPrecedenceLevel(TMinus, true);

        setPrecedenceLevel(TStar);
        setPrecedenceLevel(TSlash, true);
        setPrecedenceLevel(TPercent, true);
    }


    function requiresSemicolon(expr:Expr):Bool
    {
        return switch (expr.type)
        {
            case EBlock(_):
                false;

            case EFunction(_, _, body):
                !body.type.match(EBlock(_));

            case EIf(_, thenExpr, elseExpr):
                requiresSemicolon(thenExpr) || (elseExpr != null && requiresSemicolon(elseExpr));

            default:
                true;
        }
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

                final isBlock:Bool = check(TLBrace);

                var val:Expr = parseExpr();

                if (isBlock)
                    semicolon();
                else
                    val = fastExpr(EBlock([val]), cur);

                fastExpr(EFunction(id, arguments, val), cur);

            default:
                parseExpr();
        };

        if (res != null && requiresSemicolon(res))
        {
            trace(res);

            semicolon();
        }

        return res;
    }

    function parseExpr(?minPrec:Int = 0):Expr
    {
        var left:Expr = parsePostfix();

        while (!end())
        {
            final op:Token = peek();

            final prec:Int = precedence(op.type);

            if (prec < minPrec)
                break;

            advance();

            left = fastExpr(EBinOp(op.type, left, parseExpr(prec + associativity(op.type))), op);
        }

        return left;
    }

    function parsePostfix():Expr
    {
        var expr:Expr = parsePrefix();

        while (!end())
        {
            switch (peek().type)
            {
                case TDot:
                    advance();

                    expr = fastExpr(
                        EField(expr, switch (advance().type)
                        {
                            case TIdent(id):
                                id;

                            default:
                                expectedError(TIdent(null), last().type);

                                null;
                        }),
                        last()
                    );

                case TLParen:
                    expr = fastExpr(
                        ECall(expr, parseCallArguments()),
                        last()
                    );

                default:
                    return expr;
            }
        }

        return expr;
    }

    function parsePrefix():Expr
    {
        return switch (peek().type)
        {
            case TMinus:
                advance();

                fastExpr(EUnOp(TMinus, parseExpr(NEXT_PRECEDENCE)), last());

            case TNot:
                advance();

                fastExpr(EUnOp(TNot, parseExpr(NEXT_PRECEDENCE)), last());

            default:
                parsePrimitive();
        }
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

            case TReturn:
                advance();

                fastExpr(EReturn(parseExpr()), cur);

            case TLParen:
                advance();

                final expr:Expr = parseExpr();

                expect(TRParen);

                expr;

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

            case TFalse:
                fastAdvanceExpr(EFalse, cur);

            case TTrue:
                fastAdvanceExpr(ETrue, cur);
                
            default:
                advance();

                null;
        }
    }


    function associativity(type:TokenType):Int
    {
        return switch (type)
        {
            case TEqual:
                0;

            default:
                1;
        }
    }


    var precedenceMap:Map<TokenType, Int> = [];
    
    var NEXT_PRECEDENCE(default, null):Int = 1;

    inline function precedence(type:TokenType):Int
        return precedenceMap[type] ?? -1;

    function setPrecedenceLevel(type:TokenType, ?same:Bool = false)
    {
        final prec:Int = NEXT_PRECEDENCE - (same ? 1 : 0);
        
        if (NEXT_PRECEDENCE < prec + 1)
            NEXT_PRECEDENCE = prec + 1;

        precedenceMap[type] = prec;
    }

    
    var index:Int = 0;

    inline function peek():Token
        return end() ? null : source[index];

    inline function advance():Token
        return end() ? null : source[index++];

    inline function last():Token
        return end() ? null : source[index - 1];

    inline function next():Token
        return end() ? null : source[index + 1];

    inline function end():Bool
        return index >= length;


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
        if (check(TEqual))
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


    inline function check(type:TokenType):Bool
        return peek().type == type;
    
    function expect(type:TokenType):Void
        if (!end() && check(type))
            advance();
        else
            throw 'Expected ' + type + ', got ' + peek().type;

    inline function expectedError(expected:TokenType, got:TokenType):Void
        throw 'Expected ' + expected + ', got ' + got;
}