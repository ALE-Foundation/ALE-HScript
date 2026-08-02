package ale.hscript.lexer;

import ale.hscript.utils.ScriptPos;
import ale.hscript.utils.PosData;

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

            final cur = peek();

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
                            throw 'Unterminated comment';

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

            final startPos:PosData = fastPosData();

            final symbolToken:Token = fastToken(switch (cur)
            {
                case ':'.code:
                    TColon;

                case ';'.code:
                    TSemiColon;

                case ','.code:
                    TComma;

                case '.'.code:
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

                case '?'.code:
                    TQuestion;

                case '='.code:
                    if (match('>'.code))
                        TMapArrow;
                    else
                        TEqual;

                case '<'.code:
                    TLess;

                case '>'.code:
                    TGreater;

                case '-'.code:
                    if (match('>'.code))
                        TArrow;
                    else
                        TMinus;

                case '+'.code:
                    TPlus;

                case '*'.code:
                    TStar;

                case '/'.code:
                    TSlash;

                case '%'.code:
                    TPercent;

                case '!'.code:
                    TNot;
                
                default:
                    null;
            });

            if (symbolToken != null)
            {
                result.push(symbolToken);

                advance();

                continue;
            }

            if (cur == '\''.code || cur == '"'.code)
            {
                advance();
                
                final start:Int = index;
                final startPos:PosData = fastPosData();

                while (peek() != cur)
                {
                    advance();
                    
                    if (index >= length)
                        throw 'Unterminated String';
                }

                result.push({
                    type: TString(source.substr(start, index - start)),
                    pos: {
                        start: startPos,
                        end: fastPosData()
                    }
                });

                advance();

                continue;
            }

            if (isDigitStart(cur))
            {
                if (cur == '0'.code && (match('x'.code) || match('X'.code)))
                {
                    advance();

                    while (isHex(peek()))
                        advance();

                    result.push({
                        type: TNumber(Std.parseInt(source.substr(start, index - start))),
                        pos: {
                            start: startPos,
                            end: fastPosData()
                        }
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

                    if (!usedPoint && peek() == '.'.code)
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

                result.push({
                    type: TNumber(Std.parseFloat(source.substr(start, index - start))),
                    pos: {
                        start: startPos,
                        end: fastPosData()
                    }
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
                    pos: {
                        start: startPos,
                        end: fastPosData()
                    }
                });

                continue;
            }
            
            advance();
        }

        return result;
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
        return isDigit(c) || c == '.'.code;
    

    inline function fastPosData():PosData
        return {
            index: index,
            line: line,
            column: column
        };

    inline function fastPos():ScriptPos
        return {
            start: fastPosData()
        };

    inline function fastToken(type:TokenType):Token
    {
        if (type == null)
            return null;

        return {
            type: type,
            pos: fastPos()
        }
    }
}