package ale.hscript.interp.bytecode;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.parser.Expr;

class Compiler
{
    public function new() {}

    var code:Code;

    public final instructions:Array<Int> = [];

    public final constants:Array<Dynamic> = [];
    
    public function compile(source:Array<Expr>):Code
    {
        code = new Code();

        for (expr in source)
            emitExpr(expr);

        return code;
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


            case ETypedef(_):

            case EAlias(_, _):


            case EVar(id):
                emit(IVar);

                emitConstant(id);

            case EField(object, property):
                emitExpr(object);

                emit(IField);

                emitConstant(property);

            case EType(module):
                emit(IType);

                emitConstant(module);

            case EArrayAccess(obj, key):
                emitExpr(key);
                emitExpr(obj);

                emit(IArrayAccess);


            case ECall(obj, arguments):
                reverseEach(arguments, arg -> emitExpr(arg));

                emitExpr(obj);

                emit(ICall);

                emitConstant(arguments.length);

            case ENew(cls, args):
                reverseEach(args, arg -> emitExpr(arg));

                emitExpr(cls);

                emit(INew);

                emitConstant(args.length);


            /*
            case EFunction(args, block):
            */

            case EBlock(exprs):
                emit(IBlock);

                final oldCode:Code = code;

                final blockCode = new Code();

                code = blockCode;

                for (expr in exprs)
                    emitExpr(expr);

                code = oldCode;

                emitConstant(blockCode);


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

            case EEof:

            default:
                error(EInvalidExpression(expr.type), expr);
        }
    }

    function emit(type:Inst)
        code.instructions.push(type);

    function emitConstant(value:Dynamic)
        code.instructions.push(addConstant(value));

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
        code.constants.push(value);

        return code.constants.length - 1;
    }

    inline function error(type:ErrorType, expr:Expr)
        throw new Error(type, expr.line, expr.column);
}