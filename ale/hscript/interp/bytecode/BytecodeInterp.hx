package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

class BytecodeInterp extends BaseInterp
{
    public function execute(exprs:Array<Expr>):Dynamic
    {
        final insts:Compiler = new Compiler().compile(exprs);

        return null;
    }
}