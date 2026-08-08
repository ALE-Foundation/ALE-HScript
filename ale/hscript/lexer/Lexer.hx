package ale.hscript.lexer;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

using StringTools;

class Lexer
{
    final source:String;
    final length:Int;

    public function new(source:String)
    {
        this.source = source;

        length = source.length;
    }


    public function tokenize():Array<Token>
    {
        final result:Array<Token> = [];

        while (index < length)
        {
            final cur:Int = peek();

            if (isSpace(cur))
            {
                advance();

                continue;
            }

            if (cur == '/'.code)
            {
                final next = next();

                if (next == '/'.code)
                {
                    advance();
                    advance();

                    while (peek() != '\n'.code && peek() != -1)
                        advance();

                    continue;
                }

                if (next == '*'.code)
                {
                    advance();
                    advance();

                    while (true)
                    {
                        if (peek() == -1)
                            error(EUnterminatedComment);

                        if (peek() == '*'.code && index + 1 < length && source.fastCodeAt(index + 1) == '/'.code)
                        {
                            advance();
                            advance();

                            break;
                        }

                        advance();
                    }

                    continue;
                }
            }

            final start:Int = index;

            final tokenLine:Int = line;
            final tokenColumn:Int = column;

            if (isDigitStart(cur))
            {
                if (cur == '0'.code && (match('x'.code) || match('X'.code)))
                {
                    advance();

                    while (isHex(peek()))
                        advance();

                    final num:Null<Int> = Std.parseInt(source.substr(start, index - start));

                    if (num == null)
                        error(EInvalidNumber);

                    result.push({
                        type: TNumber(num),
                        line: tokenLine,
                        column: tokenColumn
                    });

                    continue;
                }

                var usedPoint:Bool = false;
                var usedExponent:Bool = false;

                while (true)
                {
                    if (isDigit(peek()))
                    {
                        advance();

                        continue;
                    }

                    if (!usedPoint && peek() == '.'.code && next() != '.'.code)
                    {
                        usedPoint = true;

                        advance();

                        continue;
                    }

                    if (!usedExponent && (peek() == 'e'.code || peek() == 'E'.code))
                    {
                        usedExponent = true;

                        advance();

                        if (peek() == '+'.code || peek() == '-'.code)
                            advance();

                        continue;
                    }

                    break;
                }

                final num:Null<Float> = Std.parseFloat(source.substr(start, index - start));

                if (num == null)
                    error(EInvalidNumber);

                result.push({
                    type: TNumber(num),
                    line: tokenLine,
                    column: tokenColumn
                });

                continue;
            }

            final symbolToken:TokenType = switch (cur)
            {
                case ':'.code:
                    TColon;

                case ';'.code:
                    TSemicolon;

                case ','.code:
                    TComma;

                case '.'.code:
                    if (match('.'.code) && match('.'.code))
                        TTripleDot;
                    else
                        TDot;

                case '('.code:
                    TLParen;

                case ')'.code:
                    TRParen;

                case '{'.code:
                    TLBrace;

                case '}'.code:
                    TRBrace;

                case '['.code:
                    TLBracket;

                case ']'.code:
                    TRBracket;

                case '@'.code:
                    TAt;

                case '$'.code:
                    TDollar;

                case '?'.code:
                    if (match('?'.code))
                    {
                        if (match('='.code))
                            TDoubleQuestionEqual;
                        else
                            TDoubleQuestion;
                    } else if (match('.'.code))
                        TQuestionDot;
                    else
                        TQuestion;

                case '='.code:
                    if (match('>'.code))
                        TFatArrow;
                    else if (match('='.code))
                        TDoubleEqual;
                    else
                        TEqual;

                case '!'.code:
                    if (match('='.code))
                        TExclamationEqual;
                    else
                        TExclamation;

                case '<'.code:
                    if (match('<'.code))
                    {
                        if (match('='.code))
                            TDoubleLessEqual;
                        else
                            TDoubleLess;
                    } else if (match('='.code))
                        TLessEqual;
                    else
                        TLess;

                case '>'.code:
                    TGreater;

                case '-'.code:
                    if (match('>'.code))
                        TArrow;
                    else if (match('-'.code))
                        TDoubleMinus;
                    else if (match('='.code))
                        TMinusEqual;
                    else
                        TMinus;

                case '+'.code:
                    if (match('+'.code))
                        TDoublePlus;
                    else if (match('='.code))
                        TPlusEqual;
                    else
                        TPlus;

                case '*'.code:
                    if (match('='.code))
                        TStarEqual;
                    else
                        TStar;

                case '/'.code:
                    if (match('='.code))
                        TSlashEqual;
                    else
                        TSlash;

                case '%'.code:
                    if (match('='.code))
                        TPercentEqual;
                    else
                        TPercent;

                case '&'.code:
                    if (match('&'.code))
                        TDoubleAmpersand;
                    else if (match('='.code))
                        TAmpersandEqual;
                    else
                        TAmpersand;

                case '|'.code:
                    if (match('|'.code))
                        TDoublePipe;
                    else if (match('='.code))
                        TPipeEqual;
                    else
                        TPipe;

                case '^'.code:
                    if (match('='.code))
                        TCaretEqual;
                    else
                        TCaret;

                case '~'.code:
                    TTilde;

                default:
                    null;
            };

            if (symbolToken != null)
            {
                result.push({
                    type: symbolToken,
                    line: tokenLine,
                    column: tokenColumn
                });

                advance();

                continue;
            }

            if (cur == '\''.code || cur == '"'.code)
            {
                advance();

                final res:StringBuf = new StringBuf();

                while (peek() != cur)
                {
                    final char:Int = advance();

                    if (index >= length)
                        error(EUnterminatedString);

                    res.addChar(
                        switch (char)
                        {
                            case '\\'.code:
                                final escape:Int = advance();

                                switch (escape)
                                {
                                    case 't'.code:
                                        '\t'.code;

                                    case 'n'.code:
                                        '\n'.code;

                                    case 'r'.code:
                                        '\r'.code;

                                    case '"'.code:
                                        '\"'.code;

                                    case "'".code:
                                        '\''.code;

                                    case '\\'.code:
                                        '\\'.code;

                                    case 'x'.code:
                                        readHex(2);

                                    case 'u'.code:
                                        if (peek() == '{'.code)
                                        {
                                            advance();

                                            readUnicode();
                                        } else
                                            readHex(4);

                                    case c if (c >= '0'.code && c <= '7'.code):
                                        readOctal(escape);

                                    default:
                                        error(EInvalidEscape(escape));

                                        0;
                                }

                            default:
                                char;
                        }
                    );
                }

                advance();

                result.push({
                    type: TString(res.toString()),
                    line: tokenLine,
                    column: tokenColumn
                });

                continue;
            }

            if (isIdentStart(cur))
            {
                advance();

                while (isIdentPart(peek()))
                    advance();

                final ident:String = source.substr(start, index - start);

                result.push({
                    type: TokenUtil.stringToTokenType.exists(ident) ? TokenUtil.stringToTokenType[ident] : TIdent(ident),
                    line: tokenLine,
                    column: tokenColumn
                });

                continue;
            }

            error(EInvalidCharacter(cur));
        }

        result.push({
            type: TEof,
            line: line,
            column: column
        });

        return result;
    }


    function readHex(length:Int):Int
    {
        var value:Int = 0;

        for (_ in 0...length)
        {
            final c:Int = advance();

            if (c == -1)
                error(EUnterminatedString);

            if (!isHex(c))
                error(EInvalidEscape(c));

            value <<= 4;

            value |= hexValue(c);
        }

        return value;
    }

    function readUnicode():Int
    {
        var value:Int = 0;

        while (peek() != '}'.code)
        {
            final c:Int = advance();

            if (c == -1)
                error(EUnterminatedString);

            if (!isHex(c))
                error(EInvalidEscape(c));

            value <<= 4;

            value |= hexValue(c);
        }

        if (value > 0x10FFFF)
            error(EInvalidEscape(value));

        advance();

        return value;
    }

    function readOctal(first:Int):Int
    {
        var value:Int = first - '0'.code;

        for (_ in 0...2)
        {
            if (!isDigit(peek()) || peek() > '7'.code)
                break;

            value = (value << 3) | (advance() - '0'.code);
        }

        return value;
    }

    
    var index:Int = 0;
    var line:Int = 1;
    var column:Int = 1;

    inline function peek():Int
        return index < length ? source.fastCodeAt(index) : -1;

    inline function next():Int
        return index + 1 < length ? source.fastCodeAt(index + 1) : -1;

    function match(c:Int):Bool
    {
        final res:Bool = next() == c;

        if (res)
            advance();

        return res;
    }

    function advance():Int
    {
        if (index >= length)
            return -1;

        final char:Int = source.fastCodeAt(index++);

        if (char == '\n'.code)
        {
            line++;

            column = 1;
        } else {
            column++;
        }

        return char;
    }

    inline function hexValue(c:Int):Int
        return c <= '9'.code ? c - '0'.code : c <= 'F'.code ? c - 'A'.code + 10 : c - 'a'.code + 10;

    inline function isLower(c:Int):Bool
        return c >= 'a'.code && c <= 'z'.code;

    inline function isUpper(c:Int):Bool
        return c >= 'A'.code && c <= 'Z'.code;

    inline function isLetter(c:Int):Bool
        return isLower(c) || isUpper(c);

    inline function isIdentStart(c:Int):Bool
        return isLetter(c) || c == '_'.code;

    inline function isIdentPart(c:Int):Bool
        return isIdentStart(c) || (c >= '0'.code && c <= '9'.code);

    inline function isHex(c:Int):Bool
        return (c >= '0'.code && c <= '9'.code) || (c >= 'a'.code && c <= 'f'.code) || (c >= 'A'.code && c <= 'F'.code);

    inline function isDigit(c:Int):Bool
        return c >= '0'.code && c <= '9'.code;

    inline function isDigitStart(c:Int):Bool
        return isDigit(c) || (c == '.'.code && isDigit(next()));

    inline function isSpace(c:Int):Bool
        return c == ' '.code || c == '\t'.code || c == '\r'.code || c == '\n'.code;

    inline function error(type:ErrorType):Void
        throw new Error(type, line, column);
}