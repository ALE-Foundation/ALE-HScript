package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

class Compiler
{
    public function new() {}

    public final instructions:Array<Int> = [];

    public final constants:Array<Dynamic> = [];
    
    public function compile(source:Array<Expr>):Compiler
    {
        instructions.resize(0);
        constants.resize(0);

        for (expr in source)
            emitExpr(expr);

        return this;
    }

    function emitExpr(expr:Expr)
    {
        switch (expr.type)
        {
            case ENumber(value):
                emit(CONST);
                emit(addConstant(value));

            case EString(value):
                emit(CONST);
                emit(addConstant(value));

            case EVarDecl(name, value, _, _, _):
                emitExpr(value);

                emit(SET_VAR);
                emit(addConstant(name));

            case EVar(name):
                emit(GET_VAR);
                emit(addConstant(name));

            case ECall(object, args):
                emitExpr(object);
                
                for (arg in args)
                    emitExpr(arg);

                emit(CALL);
                emit(args.length);

            default:
        }
    }

    function emit(type:Inst)
        instructions.push(type);

    function addConstant(value:Dynamic):Int
    {
        constants.push(value);

        return constants.length - 1;
    }
}