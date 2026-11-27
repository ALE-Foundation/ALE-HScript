package ale.hscript.bytecode;

import ale.hscript.parser.Expr;

class Compiler
{
    final source:Array<Expr>;

    public function new(source:Array<Expr>)
        this.source = source;

    public function compile():CompilerData
    {
        final data = {
            instructions: [],
            constants: [],
            posInfos: []
        };

        trace(data);

        return data;
    }
}