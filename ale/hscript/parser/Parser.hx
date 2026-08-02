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
            result.push(parseSemicolonStatement());

        return result;
    }


    function requiresSemicolon(expr:ExprType):Bool
        return switch (expr)
        {
            case ETry(_, _), EBlock(_), EFunctionDecl(_, _), EFunction(_, _):
                false;

            default:
                true;
        }


    function parseSemicolonStatement():Expr
    {
        final res:Expr = parseStatement();

        semicolon(res.type);

        return res;
    }
    
    function parseStatement():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TVar, TFinal:
                advance();

                final id:String = expectIdent();

                var getter:Property = PDefault;
                var setter:Property = PDefault;

                if (cur.type == TVar)
                {
                    if (check(TLParen))
                    {
                        advance();

                        getter = expectProperty();

                        expect(TComma);

                        setter = expectProperty();

                        expect(TRParen);
                    }
                } else {
                    setter = PNever;
                }

                parseOptionalType();

                fastExpr(EVarDecl(id, parseOptionalValue(), getter, setter), cur);

            case TTry:
                advance();

                final body:Expr = parseBody();

                expect(TCatch);

                expect(TLParen);

                final arg:FunctionArgument = parseFunctionArgument();

                expect(TRParen);

                fastExpr(ETry(body, arg, parseBody()), cur);

            case TUntyped:
                advance();

                parseStatement();

            case TFunction:
                advance();

                final id:String = expectIdent();

                final args:Array<FunctionArgument> = parseFunctionArguments();

                parseOptionalType();

                fastExpr(EFunctionDecl(id, fastExpr(EFunction(args, parseBody()), cur)), cur);

            case TReturn:
                advance();

                var res:Expr = null;

                if (!check(TSemiColon))
                    res = parseExpr();

                fastExpr(EReturn(res), cur);

            default:
                parseExpr();
        }
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

                case TEqual:
                    advance();

                    expr = fastExpr(EAssign(expr, parseExpr()), last());

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
            case TUntyped:
                advance();

                parseExpr();

            case TLParen:
                final args:Array<FunctionArgument> = parseFunctionArguments();

                expect(TArrow);

                fastExpr(EFunction(args, parseBody(false)), cur);

            case TFunction:
                advance();

                final args:Array<FunctionArgument> = parseFunctionArguments();

                parseOptionalType();

                fastExpr(EFunction(args, parseBody(false)), cur);

            case TNew:
                advance();

                final type:Expr = parseType();

                fastExpr(ENew(type, parseCallArguments()), cur);

            case TLBrace:
                advance();

                final exprs:Array<Expr> = [];

                while (!end() && !check(TRBrace))
                    exprs.push(parseSemicolonStatement());

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
                fastAdvanceExpr(EVar(id), cur);

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
                throw 'Unsupported Token: ' + cur;

                null;
        }
    }


    function expectProperty():Property
        return switch (advance().type)
        {
            case TNull:
                PNull;

            case TIdent(id):
                switch (id)
                {
                    case 'set':
                        PSet;

                    case 'get':
                        PGet;

                    case 'default':
                        PDefault;

                    case 'never':
                        PNever;

                    default:
                        error(TIdent('default'), last());

                        null;
                }

            default:
                error(TNull, last());

                null;
        }


    function parseBody(?stmt:Bool = true):Expr
    {
        var res:Expr = parseStatement();

        if (stmt)
            semicolon(res.type);

        if (!res.type.match(EBlock(_)))
        {
            if (!stmt && !res.type.match(EReturn(_)))
                res = {
                    type: EReturn(res),
                    pos: res.pos
                }

            res = {
                type: EBlock([res]),
                pos: res.pos
            };
        }

        return res;
    }

    
    function parseFunctionArguments():Array<FunctionArgument>
    {
        final result:Array<FunctionArgument> = [];

        expect(TLParen);

        while (!end() && !check(TRParen))
        {
            result.push(parseFunctionArgument());

            if (check(TComma))
                advance();
            else
                break;
        }

        expect(TRParen);

        return result;
    }

    function parseFunctionArgument():FunctionArgument
    {
        if (check(TQuestion))
            advance();

        final name:String = expectIdent();

        parseOptionalType();

        return {
            id: name,
            value: parseOptionalValue()
        };
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

    function parseType():Expr
    {
        final module:StringBuf = new StringBuf();

        final token:Token = peek();

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

            case TIdent(name):
                module.add(name);

                while (!end() && check(TDot))
                {
                    advance();

                    module.add('.' + expectIdent());
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

        return fastExpr(EType(module.toString()), token);
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


    inline function semicolon(type:ExprType)
        if (requiresSemicolon(type))
            expect(TSemiColon);


    function error(want:TokenType, ?got:Token)
    {
        got ??= peek();

        throw 'Expected ' + want + ', got ' + got.type;
    }


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