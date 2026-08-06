package ale.hscript.utils;

import ale.hscript.lexer.TokenType;

import haxe.Exception;

class Error extends Exception
{
    public final type:ErrorType;

    public final line:Int;
    public final column:Int;

    public function new(type:ErrorType, line:Int, column:Int)
    {
        super(format(type));

        this.type = type;

        this.line = line;
        this.column = column;
    }

    static function format(type:ErrorType):String
        return switch (type)
        {


            default:
                Std.string(type);
        }

    static function formatToken(type:TokenType):String
        return switch (type)
        {
            default:
                Std.string(type);
        }

    override function toString():String
        return '$line:$column: $message';
}