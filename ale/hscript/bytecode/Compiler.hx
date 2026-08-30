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


            case ETypedef(_, _):

            
            case EAlias(id, type):
                emitExpr(type);

                emit(IAlias);

                emitConstant(id);


            case EVar(id):
                emit(IVar);

                emitConstant(id);

            case EField(obj, prop):
                emitExpr(obj);

                emit(IField);

                emitConstant(prop);

            case EType(module):
                emit(IType);

                emitConstant(module);

            case EArrayAccess(obj, key):
                emitExpr(key);
                emitExpr(obj);

                emit(IArrayAccess);


            case ECall(obj, args):
                emitArray(args);

                emitExpr(obj);

                emit(ICall);

                emitConstant(args.length);

            case ENew(cls, args):
                emitArray(args);

                emitExpr(cls);

                emit(INew);

                emitConstant(args.length);


            case EFunction(args, body):
                reverseEach(args, arg -> emitExpr(arg.value));

                final jump:Int = emitJump();

                final start:Int = instructions.length;

                emitExpr(body);

                emitJumpExit();

                patchJump(jump);

                emit(IFunction);

                emitConstant(args.length);

                for (arg in args)
                    emitConstant(arg.id);

                emitConstant(start);

            case EBlock(exprs):
                emit(IEnterScope);

                for (expr in exprs)
                    emitExpr(expr);

                emit(IExitScope);

            
            case EReturn(val):
                emitExpr(val);

                emit(IReturn);


            case EString(str):
                pushConstant(str);

            case ENumber(num):
                pushConstant(num);

            case ENull:
                pushConstant(null);
            

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

    function emitJumpExit()
    {
        emitExpr(null);

        emit(IReturn);
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

    inline function emitArray(arr:Array<Expr>)
        reverseEach(arr, expr -> emitExpr(expr));
        

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