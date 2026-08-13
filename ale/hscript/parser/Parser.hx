package ale.hscript.parser;

import ale.hscript.lexer.TokenUtil;
import ale.hscript.lexer.TokenType;
import ale.hscript.lexer.Token;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import haxe.ds.StringMap;
import haxe.Exception;

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
        {
            final res:Expr = parseSemicolonStatement();
            
            if (res != null)
                result.push(res);
        }

        return result;
    }


    function requiresSemicolon(expr:ExprType):Null<Bool>
        return switch (expr)
        {
            case EEof, ETypedef(_, _), EMetadata(_, _), ESwitch(_, _, _), EIf(_, _, _), EWhile(_, _), EFor(_), EStructure(_), ETry(_, _), EBlock(_), EFunctionDecl(_, _), EFunction(_, _):
                false;

            case EReturn(val), EVarDecl(_, val, _, _, _), EAssign(_, val):
                val == null ? true : requiresSemicolon(val.type) ? true : null;

            default:
                true;
        }


    function parseSemicolonStatement():Expr
    {
        final res:Expr = parseStatement();

        semicolon(res.type);

        return res;
    }

    var allowPackage:Bool = true;
    var allowImports:Bool = true;
    var allowUsings:Bool = true;
    
    function parseStatement():Expr
    {
        final cur:Token = peek();

        if (allowPackage && check(TPackage))
        {
            allowPackage = false;

            advance();

            final str:StringBuf = new StringBuf();

            while (!end() && !check(TSemicolon))
            {
                str.add(parseIdent());

                if (match(TDot))
                    str.add('.');
                else
                    break;
            }

            return fastExpr(EPackage(str.length > 0 ? str.toString() : null), cur);
        }

        allowPackage = false;

        if (allowImports && check(TImport))
        {
            advance();

            final str:StringBuf = new StringBuf();

            while (!end() && !check(TStar))
            {
                str.add(parseIdent());

                if (match(TDot))
                {
                    if (match(TStar))
                        return fastExpr(EPackageImport(str.toString()), cur);

                    str.add('.');
                } else
                    break;
            }

            return fastExpr(EImport(str.toString()), cur);
        }

        allowImports = false;

        if (allowUsings && check(TUsing))
        {
            advance();

            return fastExpr(EUsing(parseType()), cur);
        }

        allowUsings = false;

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

            case TTypedef:
                advance();

                final id:String = parseIdent();

                expect(TEqual);

                final pos:Int = index;
                    
                try
                {
                    return fastExpr(EAlias(id, parseType()), cur);
                } catch(_:Dynamic) {
                    try
                    {
                        index = pos;

                        final fields:Array<String> = [];

                        expect(TLBrace);

                        while (!end() && !check(TRBrace))
                        {
                            match(TQuestion);

                            fields.push(parseIdent());

                            parseOptionalType();

                            if (!match(TComma))
                                break;
                        }

                        expect(TRBrace);

                        return fastExpr(ETypedef(id, fields), cur);
                    } catch(_:Dynamic) {
                        index = pos;
                        
                        final fields:Array<String> = [];

                        expect(TLBrace);

                        while (!end() && !check(TRBrace))
                        {
                            switch (peek().type)
                            {
                                case TAt:
                                    parseSemicolonStatement();

                                case TVar:
                                    advance();

                                    fields.push(parseIdent());

                                    parseOptionalType();

                                    expect(TSemicolon);

                                default:
                                    expected(TVar, peek());
                            }
                        }

                        expect(TRBrace);

                        return fastExpr(ETypedef(id, fields), cur);
                    }
                }

                null;
                
            case TIf:
                parseIf(true);

            case TFor:
                parseFor(true);

            case TDo:
                parseDoWhile();

            case TWhile:
                parseWhile(true);

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

            case TAt:
                advance();

                final id:StringBuf = new StringBuf();

                if (match(TColon))
                    id.addChar(':'.code);

                id.add(parseIdent());

                final pos:Int = index;

                var args:Array<Expr> = null;

                try
                {
                    if (check(TLParen))
                        args = parseCallArguments();
                } catch(_:Dynamic) {
                    index = pos;
                }

                fastExpr(EMetadata(id.toString(), args), cur);

            case TFunction:
                advance();

                final id:String = switch (advance().type)
                {
                    case TIdent(id):
                        id;

                    case TNew:
                        'new';

                    default:
                        expected(TVar, last());

                        null;
                }

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
                parseSwitch(cur);
                
            case TThrow:
                advance();

                fastExpr(EThrow(parseExpr()), cur);

            case TBreak:
                fastAdvanceExpr(EBreak, cur);

            case TContinue:
                fastAdvanceExpr(EContinue, cur);

            case TEof:
                fastAdvanceExpr(EEof, cur);

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
            var op:Token = advance();

            if (op.type == TGreater)
                if (match(TGreater))
                {
                    op.type = TDoubleGreater;

                    if (match(TGreater))
                    {
                        op.type = TTripleGreater;

                        if (match(TEqual))
                            op.type = TTripleGreaterEqual;
                    } else if (match(TEqual)) {
                        op.type = TDoubleGreaterEqual;
                    }
                } else if (match(TEqual))
                    op.type = TGreaterEqual;

            final info:Null<Precedence> = _precedenceMap[op.type];

            if (info == null || info.value < minPrec)
            {
                index--;

                break;
            }

            if (op.type == TQuestion)
            {
                final ifTrue:Expr = parseBinary();

                expect(TColon);

                left = fastExprFromExpr(ETernOp(left, ifTrue, parseBinary(info.value)), left);

                continue;
            }

            left = fastExprFromExpr(EBinOp(op.type, left, parseBinary(info.right ? info.value : info.value + 1)), left);
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

                    expr = fastExprFromExpr(EPostfix(op.type, expr), expr);

                case TLParen:
                    expr = fastExprFromExpr(ECall(expr, parseCallArguments()), expr);

                case TDot, TQuestionDot:
                    advance();
                    
                    expr = fastExprFromExpr(EField(expr, parseIdent()), expr);

                case TEqual:
                    advance();

                    expr = fastExprFromExpr(EAssign(expr, parseExpr()), expr);

                case TLBracket:
                    advance();

                    final key:Expr = parseExpr();

                    expect(TRBracket);

                    expr = fastExprFromExpr(EArrayAccess(expr, key), expr);

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
            case TSwitch:
                parseSwitch(cur);

            case TCast:
                advance();

                var res:Expr = if (check(TLParen))
                {
                    advance();

                    final obj:Expr = parseExpr();

                    expect(TComma);

                    final type:Expr = parseType();

                    expect(TRParen);

                    fastExpr(ECast(obj, type), cur);
                } else {
                    fastExpr(ECast(parseExpr()), cur);
                }

                res;

            case TUntyped:
                advance();

                parseExpr();

            case TLParen:
                final pos:Int = index;

                try
                {
                    advance();

                    final obj:Expr = parseExpr();

                    expect(TColon);

                    final type:Expr = parseType();

                    expect(TRParen);

                    if (check(TArrow))
                        throw null;

                    fastExpr(ECast(obj, type), cur);
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
                parseIf(false);

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

                        if (!match(TComma))
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

                final prevCur:Token = peek();

                final prevVal:Expr = switch (prevCur.type)
                {
                    case TFor:
                        parseFor(false);

                    case TDo:
                        parseDoWhile();

                    case TWhile:
                        parseWhile(false);

                    default:
                        null;
                }

                if (prevVal != null)
                {
                    expect(TRBracket);

                    return fastExpr(EArrayComprehension(prevVal), prevCur);
                }

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

                    if (!match(TComma))
                        break;
                }

                expect(TRBracket);

                fastExpr(mapStyle ? EMap(mapMembers) : EArray(arrayMembers), cur);

            case TIdent(id):
                advance();

                final typeRes:StringBuf = new StringBuf();

                typeRes.add(id);

                var res:Expr = fastExpr(EVar(id), cur);

                while (!end() && check(TDot))
                {
                    advance();

                    final newId:String = parseIdent();

                    typeRes.add('.' + newId);

                    final type:Dynamic = Type.resolveClass(typeRes.toString());

                    if (type == null)
                        res = fastExpr(EField(res, newId), cur);
                    else {
                        res = fastExpr(EType(typeRes.toString()), cur);

                        break;
                    }
                }

                res;

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
                error(EUnexpected(cur.type), cur);

                null;
        }
    }


    function parseFor(stmt:Bool):Expr
    {
        final cur:Token = advance();

        expect(TLParen);

        var indexId:String = null;
        var iterId:String = parseIdent();

        if (match(TFatArrow))
        {
            indexId = iterId;
            iterId = parseIdent();
        }

        expect(TIn);

        final iter = parseExpr();

        expect(TRParen);

        return fastExpr(
            EFor(indexId, iterId, iter, parseBody(stmt)),
            cur
        );
    }

    function parseWhile(stmt:Bool):Expr
    {
        final cur:Token = advance();

        expect(TLParen);

        final condition = parseExpr();

        expect(TRParen);

        return fastExpr(EWhile(condition, parseBody(stmt)), cur);
    }

    function parseDoWhile():Expr
    {
        final cur:Token = advance();

        final body = parseExpr();

        expect(TWhile);

        expect(TLParen);

        final condition = parseExpr();

        expect(TRParen);

        return fastExpr(EDoWhile(condition, body), cur);
    }

    function parseIf(stmt:Bool):Expr
    {
        final cur:Token = advance();

        expect(TLParen);

        final condition = parseExpr();

        expect(TRParen);

        final body = parseBody(stmt);

        var elseBody:Expr = null;

        if (match(TElse))
            elseBody = parseBody(stmt);

        return fastExpr(EIf(condition, body, elseBody), cur);
    }

    function parseSwitch(cur:Token):Expr
    {
        final cur:Token = advance();
        
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

                case TIdent(val) if (val == 'default'):
                    advance();

                    isDefault = true;

                default:
                    expected(TCase, peek());
            }

            expect(TColon);

            final parts:Array<Expr> = [];

            while (!end() && !checkIdent('default') && !check(TCase) && !check(TRBrace))
                parts.push(parseSemicolonStatement());

            final res:Expr = fastExpr(EBlock(parts), cur);
            
            if (isDefault)
                defaultExpr = res;
            else
                cases.push({
                    condition: condition,
                    body: res
                });
        }

        expect(TRBrace);

        return fastExpr(ESwitch(obj, cases), cur);
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
                        expected(TIdent('default'), last());

                        null;
                }

            default:
                expected(TIdent(null), last());

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
                    line: res.line,
                    column: res.column
                }

            res = {
                type: EBlock([res]),
                line: res.line,
                column: res.column
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

            if (!match(TComma))
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

            if (!match(TComma))
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

                    if (!match(TComma))
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
                        expected(TComma, last());

                    parseType();

                    count++;
                }

                expect(TRParen);

                expect(TArrow);

                parseType();

            default:
                expected(TIdent(null), last());
        }

        switch (peek().type)
        {
            case TLess:
                advance();

                while (!end() && !check(TGreater))
                {
                    parseType();

                    if (!match(TComma))
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
            line: token.line,
            column: token.column
        };

    inline function fastExprFromExpr(type:ExprType, expr:Expr):Expr
        return {
            type: type,
            line: expr.line,
            column: expr.column
        };

    inline function fastAdvanceExpr(type:ExprType, token:Token):Expr
    {
        advance();

        return fastExpr(type, token);
    }


    inline function semicolon(type:ExprType):Null<Bool>
    {
        final res:Null<Bool> = requiresSemicolon(type);

        if (res == null)
            match(TSemicolon);
        else if (res)
            expect(TSemicolon);

        return res;
    }


    inline function error(type:ErrorType, ?got:Token)
    {
        got ??= peek();

        throw new Error(type, got.line, got.column);
    }

    inline function expected(type:TokenType, ?got:Token)
        error(EExpected(type, got == null ? peek().type : got.type));


    inline function expect(type:TokenType, ?got:Token)
        if (check(type))
            advance();
        else
            expected(type, got);

    function parseIdent():String
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

    inline function checkIdent(str:String):Bool
        return switch (peek().type)
        {
            case TIdent(id):
                id == str;

            default:
                false;
        }

    inline function match(type:TokenType):Bool
    {
        final res:Bool = peek().type == type;

        if (res)
            advance();

        return res;
    }


    var _precedenceCount:Int = 0;

    var _precedenceMap:Map<TokenType, Precedence> = [];

    function addPrecedence(types:Array<TokenType>, ?right:Bool = false)
    {
        for (type in types)
            _precedenceMap[type] = {
                value: _precedenceCount,
                right: right
            };

        _precedenceCount++;
    }

    function initPrecedence()
    {
        addPrecedence([
            TPercentEqual,
            TStarEqual,
            TSlashEqual,
            TPlusEqual,
            TMinusEqual,
            TDoubleLessEqual,
            TDoubleGreaterEqual,
            TTripleGreaterEqual,
            TAmpersandEqual,
            TPipeEqual,
            TCaretEqual,
            TDoubleQuestionEqual
        ], true);

        addPrecedence([TQuestion], true);

        addPrecedence([TAt], true);

        addPrecedence([TDoubleQuestion]);

        addPrecedence([TDoublePipe]);

        addPrecedence([TDoubleAmpersand]);

        addPrecedence([TTripleDot]);

        addPrecedence([
            TDoubleEqual,
            TExclamationEqual,
            TLess,
            TLessEqual,
            TGreater,
            TGreaterEqual
        ]);

        addPrecedence([
            TAmpersand,
            TPipe,
            TCaret
        ]);

        addPrecedence([
            TDoubleLess,
            TDoubleGreater,
            TTripleGreater
        ]);

        addPrecedence([
            TPlus,
            TMinus
        ]);

        addPrecedence([
            TStar,
            TSlash
        ]);

        addPrecedence([
            TPercent
        ]);
    }
}