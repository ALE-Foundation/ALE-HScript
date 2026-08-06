package ale.hscript.utils;

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
        return Std.string(type);

    override function toString():String
        return '($line:$column) $message';
}