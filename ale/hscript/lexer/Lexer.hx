package ale.hscript.lexer;

import ale.hscript.utils.PosData;

using StringTools;

class Lexer
{
    final content:String;

    public function new(content:String)
        this.content = content;

    var index:Int = 0;
    var line:Int = 1;
    var column:Int = 1;

    function getPos():PosData
        return {
            index: index,
            line: line,
            column: column
        };

    function peek():Int
        return content.fastCodeAt(index);

    function peekString():String
        return content.charAt(index);

    function advance():Int
    {
        var char = peek();

        index++;

        if (char == '\n'.code)
        {
            line++;

            column = 1;
        } else {
            column++;
        }

        return char;
    }

    function advanceString():String
        return String.fromCharCode(advance());

    function isEnd():Bool
        return index > content.length - 1;
    
    inline function isDigit(char:Int):Bool
        return char >= '0'.code && char <= '9'.code;

    inline function isIdentStart(char:Int):Bool
        return (char >= 'a'.code && char <= 'z'.code) || (char >= 'A'.code && char <= 'Z'.code) || char == '_'.code;

    inline function isIdent(char:Int):Bool
        return isIdentStart(char) || isDigit(char);

    public function tokenize():Array<Token>
    {
        final result:Array<Token> = [];

        while (!isEnd())
        {
            final cur:Int = peek();
            
            final start = getPos();

            if (isIdentStart(cur))
            {
                var res:String = '';

                while (isIdent(peek()))
                    res += advanceString();

                result.push({
                    type: TokenUtil.keywordFromString[res] ?? TIdent(res),
                    position: {
                        start: start,
                        end: getPos()
                    }
                });

                continue;
            }

            if (cur == '\''.code || cur == '"'.code)
            {
                advance();

                var res:String = '';

                while (peek() != cur)
                    res += advanceString();

                advance();

                result.push({
                    type: TString(res),
                    position: {
                        start: start,
                        end: getPos()
                    }
                });
                
                continue;
            }

            switch (cur)
            {
                case ' '.code, '\t'.code, '\n'.code, '\r'.code:
                    advance();

                default:
                    result.push({
                        type: TokenUtil.symbolFromString[advanceString()],
                        position: {
                            start: start
                        }
                    });
            }
        }

        return result;
    }
}