package ale.hscript.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

class VirtualMachine extends Interp
{
    override function execute(exprs:Array<Expr>):Dynamic
    {
        final data:CompilerData = new Compiler(exprs).compile();

        return null;
    }
}