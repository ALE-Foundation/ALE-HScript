package ale.hscript.parser;

import ale.hscript.lexer.TokenUtil;
import ale.hscript.lexer.Token;

class Parser
{
    public final tokens:Array<Token>;

    public function new(tokens:Array<Token>)
        this.tokens = tokens;

    var index:Int = 0;

    function peekLast():Token
        return tokens[index - 1];

    function peek():Token
        return tokens[index];

    function peekNext():Token
        return tokens[index + 1];

    function advance():Token
        return tokens[index++];

    function isEnd():Bool
        return index >= tokens.length;

    function error(?cur:Bool = false):Bool
    {
        throw 'Unexpected Token: ' + (cur ? peek() : peekLast());

        return false;
    }

    function expect(val:Token)
        if (advance() != val)
            throw 'Expected Token: ' + val + ', got ' + peekLast();

    public function parse():Expr
    {
        final result:Array<Expr> = [];

        while (!isEnd())
        {
            final res:Expr = parseExpr();

            if (res != null)
                result.push(res);
        }

        return EProgram(result);
    }

    function parseExpr(precedence:Precedence = NONE):Expr
    {
        var left = parsePrefix();

        while (!isEnd() && Std.int(precedence) < Std.int(getPrecedence(peek())))
            left = parsePostfix(left);

        return left;
    }

    function parsePrefix():Expr
    {
        return switch (advance())
        {
            case TLeftBrace:
                index--;

                final start:Int = index;

                try
                {
                    advance();

                    final result:Map<String, Expr> = [];

                    var shouldContinue = peek() != TRightBrace;

                    while (!isEnd() && shouldContinue)
                    {
                        final key:String = switch (advance())
                        {
                            case TIdent(n):
                                n;

                            default:
                                error();

                                null;
                        }

                        expect(TColon);

                        result[key] = parseExpr();

                        shouldContinue = switch (peek())
                        {
                            case TComma:
                                advance();

                                true;

                            default:
                                false;
                        }
                    }

                    expect(TRightBrace);

                    EStruct(result);
                } catch(_) {
                    index = start;
                    
                    advance();

                    final result:Array<Expr> = [];

                    while (!isEnd() && peek() != TRightBrace)
                    {
                        final res:Expr = parseExpr();

                        if (res != null)
                            result.push(res);
                    }

                    expect(TRightBrace);

                    EBlock(result);
                }

            case TLeftBracket:
                final values:Array<Expr> = [];

                final mapValues:Map<Expr, Expr> = [];

                var mapForm:Null<Bool> = null;

                var shouldContinue:Bool = peek() != TRightBracket;

                while (!isEnd() && shouldContinue)
                {
                    final nextExpr = parseExpr();

                    if (mapForm == null)
                    {
                        switch (peek())
                        {
                            case TComma:
                                mapForm = false;

                            case TMapArrow:
                                mapForm = true;

                            case TRightBracket:

                            default:
                                error();

                                null;
                        }
                    }

                    if (!mapForm)
                        values.push(nextExpr);

                    shouldContinue = switch (peek())
                    {
                        case TComma:
                            advance();

                            if (mapForm)
                            {
                                error();

                                false;
                            } else {
                                true;
                            }

                        case TMapArrow:
                            advance();
                            
                            if (mapForm)
                            {
                                mapValues.set(nextExpr, parseExpr());

                                switch (peek())
                                {
                                    case TComma:
                                        advance();

                                        true;

                                    case TRightBracket:
                                        false;

                                    default:
                                        error();

                                        false;
                                }
                            } else {
                                error();

                                false;
                            }

                        case TRightBracket:
                            false;

                        default:
                            error();

                            false;
                    }
                }

                expect(TRightBracket);

                mapForm == true ? EMap(mapValues) : EArray(values);
            
            case TNumber(val):
                ENumber(val);

            case TString(val):
                EString(val);

            case TTrue:
                ETrue;

            case TFalse:
                EFalse;

            case TNull:
                ENull;

            case TReturn:
                final res = parseExpr();

                expect(TSemicolon);

                EReturn(res);

            case TPackage:
                var result:String = '';

                var shouldContinue:Bool = peek() != TSemicolon;

                while (!isEnd() && shouldContinue)
                {
                    switch (advance())
                    {
                        case TIdent(n):
                            result += (result.length > 0 ? '.' : '') + n;

                        default:
                            error();

                            null;
                    };

                    shouldContinue = switch (peek())
                    {
                        case TDot:
                            advance();

                            true;

                        default:
                            false;
                    };
                }

                expect(TSemicolon);

                EPackage(result);

            case TImport:
                var wildcard:Bool = false;

                var type:String = '';

                var shouldContinue = true;
                
                while (!isEnd() && shouldContinue)
                {
                    switch (advance())
                    {
                        case TIdent(n):
                            type += (type.length > 0 ? '.' : '') + n;

                        case TStar if (type.length > 0):
                            wildcard = true;

                            break;

                        default:
                            error();

                            null;
                    }

                    shouldContinue = switch (peek())
                    {
                        case TDot:
                            advance();

                            true;

                        default:
                            false;
                    }
                }

                final nick:String = wildcard ? null : switch (peek())
                {
                    case TAs:
                        advance();

                        switch (advance())
                        {
                            case TIdent(n):
                                n;

                            default:
                                error();

                                null;
                        }

                    default:
                        null;
                }

                expect(TSemicolon);

                EImport(type, wildcard, nick);

            case TVar, TFinal:
                final name:String = switch (advance())
                {
                    case TIdent(n):
                        n;

                    default:
                        error();

                        null;
                }

                parseOptionalType();

                final value:Dynamic = switch (peek())
                {
                    case TEqual:
                        advance();

                        parseExpr();

                    default:
                        Expr.ENull;
                }

                expect(TSemicolon);

                EVar(name, value);

            case TIdent(name):
                switch (peek())
                {
                    case TArrow:
                        advance();

                        EFunction(null, [{name: name}], parseExpr());

                    default:
                        var pathVer:String = name;

                        var result:Expr = EField(null, name);

                        var shouldContinue:Bool = peek() == TDot;

                        while (!isEnd() && shouldContinue)
                        {
                            advance();

                            switch (advance())
                            {
                                case TIdent(n):
                                    if (pathVer != null)
                                        pathVer += (pathVer.length > 0 ? '.' : '') + n;
                                
                                    result = EField(result, n);

                                default:
                                    error();

                                    null;
                            }

                            if (pathVer != null)
                            {
                                final type = Type.resolveClass(pathVer);

                                if (type != null)
                                {
                                    result = EType(pathVer);

                                    pathVer = null;
                                }
                            }

                            shouldContinue = switch (peek())
                            {
                                case TDot:
                                    true;

                                default:
                                    false;
                            }
                        }

                        result;
                }
            case TLeftParen:
                index--;

                final start = index;

                try
                {
                    final args:Array<FunctionArgument> = parseFunctionArguments();

                    expect(TArrow);

                    final result:Expr = parseExpr();

                    EFunction(null, args,
                        switch (result)
                        {
                            case EBlock(_):
                                result;
                            
                            default:
                                EReturn(result);
                        }
                    );
                } catch(_) {
                    index = start;

                    expect(TLeftParen);

                    final result:Expr = parseExpr();

                    expect(TRightParen);

                    result;
                }
            
            case TExclamation, TDoublePlus, TDoubleMinus, TMinus:
                EPrefix(peekLast(), parseExpr(UNARY));

            case TFunction:
                final name = switch (peek())
                {
                    case TIdent(n):
                        advance();

                        n;

                    case TNew:
                        advance();

                        'new';

                    default:
                        null;
                }

                final args:Array<FunctionArgument> = parseFunctionArguments();

                parseOptionalType();

                EFunction(name, args, parseExpr());

            case TNew:
                ENew(parseType(), parseArguments());

            default:
                null;
        }
    }

    function parsePostfix(left:Expr):Expr
    {
        final cur:Token = peek();

        if (TokenUtil.binOps.contains(cur))
        {
            final op = advance();

            final right = parseExpr(getPrecedence(op));

            final binOp:Expr = EBinOp(left, op, right);

            return TokenUtil.assignOps.contains(cur) ? ESet(left, binOp) : binOp;
        }

        return switch (cur)
        {
            case TLeftParen:
                ECall(left, parseArguments());

            case TLeftBracket:
                advance();

                final val:Expr = parseExpr();

                expect(TRightBracket);

                EArrayAccess(left, val);

            case TEqual:
                advance();

                ESet(left, parseExpr());

            case TDoublePlus, TDoubleMinus:
                ESet(left, EPostfix(left, advance()), false);

            case TQuestion:
                advance();

                final trueCase:Expr = parseExpr(TERNARY);

                expect(TColon);

                final falseCase:Expr = parseExpr(TERNARY);

                ETernOp(left, trueCase, falseCase);

            case TDot:
                advance();

                EField(left,
                    switch (advance())
                    {
                        case TIdent(n):
                            n;

                        default:
                            error();

                            null;
                    }
                );

            default:
                advance();

                left;
        }
    }

    function parseArguments():Array<Expr>
    {
        final result:Array<Expr> = [];

        expect(TLeftParen);

        while (!isEnd() && peek() != TRightParen)
        {
            result.push(parseExpr());
            
            if (peek() == TComma)
                advance();
            else
                break;
        }

        expect(TRightParen);

        return result;
    }

    function parseFunctionArguments():Array<FunctionArgument>
    {
        final result:Array<FunctionArgument> = [];

        expect(TLeftParen);

        while (!isEnd() && peek() != TRightParen)
        {
            if (peek() == TQuestion)
                advance();

            final name:String = switch (advance())
            {
                case TIdent(n):
                    n;

                default:
                    error();

                    null;
            }

            parseOptionalType();

            var value:Dynamic = null;

            if (peek() == TEqual)
            {
                advance();

                value = parseExpr();
            }

            result.push({name: name, value: value});

            if (peek() == TComma)
                advance();
            else
                break;
        }

        expect(TRightParen);

        return result;
    }

    function parseOptionalType()
    {
        if (peek() == TColon)
        {
            advance();

            parseType();
        }
    }

    function parseType():Expr
    {
        var typeName:String = '';

        switch (advance())
        {
            case TLeftBrace:
                var shouldContinue:Bool = true;

                while (!isEnd() && shouldContinue)
                {
                    switch (advance())
                    {
                        case TIdent(_):

                        default:
                            error();

                            null;
                    }

                    parseOptionalType();

                    shouldContinue = switch (peek())
                    {
                        case TComma:
                            advance();

                            true;

                        default:
                            false;
                    }
                }

                expect(TRightBrace);

            case TIdent(name):
                typeName += name;

                while (!isEnd() && peek() == TDot)
                {
                    advance();

                    final name:String = switch (advance())
                    {
                        case TIdent(n):
                            n;

                        default:
                            error();

                            null;
                    };

                    typeName += '.' + name;
                }
                
            case TLeftParen:
                var total:Int = 0;
            
                while (!isEnd() && !peek().match(TRightParen))
                {                    
                    if (total > 0 && !advance().match(TComma))
                        error();

                    parseType();

                    total++;
                }

                expect(TRightParen);

                expect(TArrow);

                parseType();

            default:
                error();
        }

        switch (peek())
        {
            case TLess:
                advance();

                while (!isEnd() && peek() != TGreater)
                {
                    parseType();

                    switch (peek())
                    {
                        case TComma:
                            advance();

                        case TGreater:
                            break;

                        default:
                            error();

                            null;
                    }
                }

                expect(TGreater);

            case TArrow:
                advance();
                
                parseType();
                
            default:
        }

        return EType(typeName);
    }

    function getPrecedence(op:Token):Precedence
    {
        return switch (op)
        {
            case TEqual, TPlusEqual, TMinusEqual, TStarEqual, TSlashEqual, TPercentEqual, TDoubleLessEqual, TDoubleGreaterEqual, TTripleGreaterEqual, TAmpersandEqual, TPipeEqual, TCaretEqual:
                ASSIGNMENT;

            case TQuestion:
                TERNARY;

            case TDoublePipe:
                OR;

            case TDoubleAmpersand:
                AND;

            case TPipe:
                BIT_OR;

            case TCaret:
                BIT_XOR;

            case TAmpersand:
                BIT_AND;

            case TDoubleEqual, TExclamationEqual:
                EQUALITY;

            case TLess, TGreater, TLessEqual, TGreaterEqual:
                COMPARISON;

            case TDoubleLess, TDoubleGreater, TTripleGreater:
                SHIFT;

            case TPlus, TMinus:
                TERM;

            case TStar, TSlash, TPercent:
                FACTOR;

            case TExclamation, TDoublePlus, TDoubleMinus:
                UNARY;

            case TLeftParen, TLeftBracket:
                CALL;

            case TDot:
                MEMBER;

            default:
                NONE;
        }
    }
}