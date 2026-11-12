package ale.hscript.interp;

import ale.hscript.parser.FunctionArgument;
import ale.hscript.parser.Expr;

class Constructor
{
    public final pre:Expr;
    public final superArgs:Array<Expr>;
    public final post:Expr;

    public final funcArgs:Array<FunctionArgument>;

    public function new(pre:Expr, superArgs:Array<Expr>, post:Expr, funcArgs:Array<FunctionArgument>)
    {
        this.pre = pre;
        this.superArgs = superArgs;
        this.post = post;

        this.funcArgs = funcArgs;
    }
}