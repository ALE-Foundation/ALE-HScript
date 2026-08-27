package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

class Compiler
{
    public function new() {}

    final instructions:Array<Int> = [];

    final constants:Array<Dynamic> = [];
    
    public function compile(source:Array<Expr>):Compiler
    {
        instructions.resize(0);
        constants.resize(0);

        return this;
    }
}