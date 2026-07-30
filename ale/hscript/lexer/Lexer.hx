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

            final start:Int = index;

            final startPos:PosData = fastPosData();

            final symbolToken:Token = fastToken(switch (cur)
            {
                case '='.code:
                    TEqual;

                case ':'.code:
                    TColon;

                case ';'.code:
                    TSemiColon;

                case '('.code:
                    TLParen;

                case ')'.code:
                    TRParen;

                case ','.code:
                    TComma;

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
                
                final start:Int = start + 1;

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


    inline function isDigit(c:Int):Bool
        return c >= '0'.code && c <= '9'.code;
    

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