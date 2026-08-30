package ale.hscript.bytecode;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.parser.Expr;

class Compiler
{
    public function new() {}

    public final instructions:Array<Int> = [];

    public final constants:Array<Dynamic> = [];
    
    public function compile(source:Array<Expr>):Code
    {
        instructions.resize(0);
        constants.resize(0);

        for (expr in source)
            emitExpr(expr);

        return {
            instructions: instructions,
            constants: constants
        };
    }

    function emitExpr(expr:Expr)
    {
        if (expr == null)
        {
            emit(IPush);
            emitConstant(null);
         
            return;
        }

        switch (expr.type)
        {
            case EEof:

            default:
                error(EInvalidExpression(expr.type), expr);
        }
    }

    function emitJump():Int
    {
        emit(IJump);

        return emitConstant(null);
    }

    function patchJump(pos:Int)
        constants[pos] = instructions.length;
    

    function emit(type:Inst)
        instructions.push(type);

    function emitConstant(value:Dynamic):Int
    {
        constants.push(value);

        instructions.push(constants.length - 1);

        return constants.length - 1;
    }

    function reverseEach<T>(arr:Array<T>, fn:T -> Void)
    {
        var i:Int = arr.length;

        while (i-- > 0)
            fn(arr[i]);
    }

    function pushConstant(value:Dynamic)
    {
        emit(IPush);

        emitConstant(value);
    }

    inline function error(type:ErrorType, expr:Expr)
        throw new Error(type, expr.line, expr.column);
}