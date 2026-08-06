package ale.hscript.parser;

import ale.hscript.lexer.TokenUtil;
import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import haxe.ds.StringMap;

class Parser
{
    final source:Array<Token>;

    final length:Int;

    public function new(source:Array<Token>)
    {
        this.source = source;

        length = source.length;

        initPrecedence();
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
            case ESwitch(_, _, _), EIf(_, _, _), EWhile(_, _), EFor(_), EStructure(_), ETry(_, _), EBlock(_), EFunctionDecl(_, _), EFunction(_, _):
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

                final id:String = parseIdent();

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
                }

                parseOptionalType();

                fastExpr(EVarDecl(id, parseOptionalValue(), getter, setter, cur.type == TFinal), cur);

            case TIf:
                advance();

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                final body:Expr = parseBody();

                var elseBody:Expr = null;

                if (check(TElse))
                {
                    advance();

                    elseBody = parseBody();
                }

                fastExpr(EIf(condition, body, elseBody), cur);

            case TFor:
                advance();

                expect(TLParen);

                var indexId:String = null;

                var iterId:String = parseIdent();

                if (check(TFatArrow))
                {
                    advance();

                    indexId = iterId;

                    iterId = parseIdent();
                }

                expect(TIn);

                final iter:Expr = parseExpr();

                expect(TRParen);

                fastExpr(EFor(indexId, iterId, iter, parseBody()), cur);

            case TDo:
                advance();

                final body:Expr = parseExpr();

                expect(TWhile);

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                fastExpr(EDoWhile(condition, body), cur);

            case TWhile:
                advance();

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                fastExpr(EWhile(condition, parseBody()), cur);

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

                final id:String = parseIdent();

                final args:Array<FunctionArgument> = parseFunctionArguments();

                parseOptionalType();

                fastExpr(EFunctionDecl(id, fastExpr(EFunction(args, parseBody()), cur)), cur);

            case TReturn:
                advance();

                var res:Expr = null;

                if (!check(TSemicolon))
                    res = parseExpr();

                fastExpr(EReturn(res), cur);

            case TSwitch:
                advance();

                match(TLParen);

                final obj:Expr = parseExpr();

                match(TRParen);

                expect(TLBrace);

                var cases:Array<SwitchCondition> = [];

                var defaultExpr:Expr = null;

                while (!end() && !check(TRBrace))
                {
                    var condition:Expr = null;

                    var isDefault:Bool = false;

                    switch (peek().type)
                    {
                        case TCase:
                            advance();

                            condition = parseExpr();

                        case TDefault:
                            advance();

                            isDefault = true;

                        default:
                            error(TCase, peek());
                    }

                    expect(TColon);

                    final parts:Array<Expr> = [];

                    while (!end() && !check(TDefault) && !check(TCase) && !check(TRBrace))
                        parts.push(parseSemicolonStatement());

                    final res:Expr = fastExpr(EBlock(parts), last());
                    
                    if (isDefault)
                        defaultExpr = res;
                    else
                        cases.push({
                            condition: condition,
                            body: res
                        });
                }

                expect(TRBrace);

                fastExpr(ESwitch(obj, cases, defaultExpr), cur);
                
            case TThrow:
                advance();

                fastExpr(EThrow(parseExpr()), cur);

            case TBreak:
                fastAdvanceExpr(EBreak, cur);

            case TContinue:
                fastAdvanceExpr(EContinue, cur);

            default:
                parseExpr();
        }
    }

    function parseExpr():Expr
        return parseBinary();

    function parseBinary(?minPrec:Int = 0):Expr
    {
        var left:Expr = parsePrefix();

        while (!end())
        {
            var prec:Int = precedence(peek().type);

            if (prec < minPrec)
                break;

            final op:Token = advance();

            left = fastExpr(EBinOp(op.type, left, parseBinary(prec + 1)), op);
        }

        return left;
    }

    function parsePrefix():Expr
    {
        switch (peek().type)
        {
            case TExclamation, TTilde, TMinus, TDoublePlus, TDoubleMinus:
                final op:Token = advance();

                return fastExpr(EPrefix(op.type, parsePrefix()), op);

            default:
                return parsePostfix();
        }
    }

    function parsePostfix():Expr
    {
        var expr:Expr = parsePrimitive();

        while (!end())
        {
            switch (peek().type)
            {
                case TDoublePlus, TDoubleMinus:
                    final op:Token = advance();

                    expr = fastExpr(EPostfix(op.type, expr), op);

                case TLParen:
                    expr = fastExpr(ECall(expr, parseCallArguments()), last());

                case TDot, TQuestionDot:
                    advance();
                    
                    expr = fastExpr(EField(expr, parseIdent()), last());

                case TEqual:
                    advance();

                    expr = fastExpr(EAssign(expr, parseExpr()), last());

                case TLBracket:
                    advance();

                    final key:Expr = parseExpr();

                    expect(TRBracket);

                    expr = fastExpr(EArrayAccess(expr, key), last());

                case TQuestion:
                    advance();

                    final ifTrue:Expr = parseExpr();

                    expect(TColon);
                    
                    final ifFalse:Expr = parseExpr();

                    expr = fastExpr(ETernOp(expr, ifTrue, ifFalse), last());

                default:
                    return expr;
            }
        }

        return expr;
    }

    function parsePrimitive():Expr
    {
        final cur:Token = peek();

        return switch (cur.type)
        {
            case TCast:
                advance();

                if (check(TLParen))
                    fastExpr(ECall(fastExpr(EVar('cast'), cur), parseCallArguments()), cur);
                else
                    parseExpr();

            case TUntyped:
                advance();

                parseExpr();

            case TLParen:
                final pos:Int = index;

                try
                {
                    advance();

                    final res:Expr = parseExpr();

                    expect(TColon);

                    parseType();

                    expect(TRParen);

                    if (check(TArrow))
                        throw null;

                    res;
                } catch(_:Dynamic) {
                    try
                    {
                        index = pos;

                        final args:Array<FunctionArgument> = parseFunctionArguments();

                        expect(TArrow);

                        fastExpr(EFunction(args, parseBody(false)), cur);
                    } catch(_:Dynamic) {
                        index = pos;

                        advance();

                        final res:Expr = parseExpr();

                        expect(TRParen);

                        res;
                    }
                }
                
            case TIf:
                advance();

                expect(TLParen);

                final condition:Expr = parseExpr();

                expect(TRParen);

                final body:Expr = parseBody(false);

                var elseBody:Expr = null;

                if (check(TElse))
                {
                    advance();

                    elseBody = parseBody(false);
                }

                fastExpr(EIf(condition, body, elseBody), cur);

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

                final pos:Int = index;

                final res:ExprType = try
                {
                    final values:StringMap<Expr> = new StringMap<Expr>();

                    while (!end() && !check(TRBrace))
                    {
                        final key:String = parseIdent();

                        expect(TColon);

                        values.set(key, parseExpr());

                        if (check(TComma))
                            advance();
                        else
                            break;
                    }

                    EStructure(values);
                } catch(_:Dynamic) {
                    index = pos;

                    final exprs:Array<Expr> = [];

                    while (!end() && !check(TRBrace))
                        exprs.push(parseSemicolonStatement());

                    EBlock(exprs);
                }

                expect(TRBrace);

                fastExpr(res, cur);

            case TLBracket:
                advance();

                final arrayMembers:Array<Expr> = [];
                final mapMembers:Map<Expr, Expr> = [];

                var mapStyle:Null<Bool> = null;

                while (!end() && !check(TRBracket))
                {
                    final left:Expr = parseExpr();

                    if (mapStyle == null)
                        mapStyle = check(TFatArrow);

                    if (mapStyle)
                    {
                        expect(TFatArrow);

                        mapMembers.set(left, parseExpr());
                    } else {
                        arrayMembers.push(left);
                    }

                    if (check(TComma))
                        advance();
                    else
                        break;
                }

                expect(TRBracket);

                fastExpr(mapStyle ? EMap(mapMembers) : EArray(arrayMembers), cur);

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

        final name:String = parseIdent();

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
                    parseIdent();

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

                    module.add('.' + parseIdent());
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
            expect(TSemicolon);


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

    function parseIdent():String
        return switch (advance().type)
        {
            case TIdent(id):
                id;

            default:
                expect(TIdent(null), last());

                null;
        }


    var _precedenceCount:Int = 0;

    var _precedenceMap:Map<TokenType, Int> = [];

    function addPrecedence(type:TokenType, ?repeat:Bool = false)
        _precedenceMap[type] = repeat ? _precedenceCount : ++_precedenceCount;

    function initPrecedence()
    {
        addPrecedence(TEqual);
        addPrecedence(TPlusEqual, true);
        addPrecedence(TMinusEqual, true);
        addPrecedence(TStarEqual, true);
        addPrecedence(TSlashEqual, true);
        addPrecedence(TPercentEqual, true);
        addPrecedence(TAmpersandEqual, true);
        addPrecedence(TPipeEqual, true);
        addPrecedence(TCaretEqual, true);
        addPrecedence(TDoubleLessEqual, true);
        addPrecedence(TDoubleGreaterEqual, true);
        addPrecedence(TTripleGreaterEqual, true);

        addPrecedence(TTripleDot);

        addPrecedence(TDoubleQuestion);

        addPrecedence(TDoublePipe);

        addPrecedence(TDoubleAmpersand);

        addPrecedence(TPipe);

        addPrecedence(TCaret);

        addPrecedence(TAmpersand);

        addPrecedence(TDoubleEqual);
        addPrecedence(TExclamationEqual, true);

        addPrecedence(TLess);
        addPrecedence(TGreater, true);
        addPrecedence(TLessEqual, true);
        addPrecedence(TGreaterEqual, true);

        addPrecedence(TDoubleLess);
        addPrecedence(TDoubleGreater, true);
        addPrecedence(TTripleGreater, true);

        addPrecedence(TPlus);
        addPrecedence(TMinus, true);

        addPrecedence(TStar);
        addPrecedence(TSlash, true);
        addPrecedence(TPercent, true);
    }

    function precedence(token:TokenType):Int
        return _precedenceMap[token] ?? -1;

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

    inline function match(type:TokenType):Bool
    {
        final res:Bool = peek().type == type;

        if (res)
            advance();

        return res;
    }
}