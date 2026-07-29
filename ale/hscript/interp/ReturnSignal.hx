package ale.hscript.interp;

import ale.hscript.parser.Expr;

class ReturnSignal
{
    public var value:Dynamic;

    public function new(value:Dynamic)
        this.value = value;
}