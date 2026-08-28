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
            case EVarDecl(id, value, getter, setter, isFinal):
                emitExpr(value);
                
                emit(IVarDecl);

                emitConstant(id);

                emitConstant(getter);
                emitConstant(setter);
                emitConstant(isFinal);

            case EFunctionDecl(id, value):
                emitExpr(value);

                emit(IFunctionDecl);

                emitConstant(id);

            case EVar(id):
                emit(IVar);

                emitConstant(id);

            case EField(object, property):
                emitExpr(object);

                emit(IField);

                emitConstant(property);

            case ECall(obj, arguments):
                reverseEach(arguments, arg -> emitExpr(arg));

                emitExpr(obj);

                emit(ICall);

                emitConstant(arguments.length);

            case EString(str):
                pushConstant(str);

            /*
            case EInterpolatedString(parts):
            */

            case ENumber(num):
                pushConstant(num);

            /*
            case EArray(members):

            case EArrayComprehension(expr):

            case EMap(members):
            */

            case EStructure(values):
                final keys:Array<String> = [];

                for (id => expr in values)
                {
                    emitExpr(expr);

                    keys.push(id);
                }

                emit(IStructure);

                emitConstant(keys.length);

                reverseEach(keys, key -> emitConstant(key));

            default:
        }
    }

    function emit(type:Inst)
        instructions.push(type);

    function emitConstant(value:Dynamic)
        instructions.push(addConstant(value));

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

    function addConstant(value:Dynamic):Int
    {
        constants.push(value);

        return constants.length - 1;
    }
}