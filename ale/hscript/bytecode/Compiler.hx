package ale.hscript.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.errors.ErrorType;

class Compiler
{
    final source:Array<Expr>;

    public function new(source:Array<Expr>)
        this.source = source;

    final data:CompilerData = {
        instructions: [],
        constants: [],
        posInfos: []
    };

    public function compile():CompilerData
    {
        for (expr in source)
            emitExpr(expr);

        return data;
    }

    function emitExpr(expr:Expr)
    {
        switch (expr.type)
        {   
            case EVarDecl(id, value, access, getter, setter, isFinal):
                emitExpr(value);

                emit(IVarDecl);

                emitConstant(id);
                
                emitConstantArray(access);

                emitConstant(getter);
                emitConstant(setter);
                emitConstant(isFinal);

            case EFunctionDecl(id, access, value, overr):
                emitExpr(value);

                emit(IFunctionDecl);

                emitConstant(id);

                emitConstantArray(access);

                emitConstant(overr);

            case ECall(object, args):
                emitExpr(object);

                emitExprArray(args);

                emit(ICall);

            case EVar(id):
                emit(IVar);

                emitConstant(id);

            case EString(str):
                emitConstantPush(str);

            case ENumber(num):
                emitConstantPush(num);

            case EEof:

            default:
                throw EInvalidExpression(expr.type);
        }
    }

    function emitConstantArray(arr:Array<Dynamic>)
    {
        emitConstant(arr.length);

        for (obj in arr)
            emitConstant(obj);
    }

    function emitExprArray(arr:Array<Expr>)
    {
        for (obj in arr)
            emitExpr(obj);

        emitConstantPush(arr.length);
    }

    function emit(type:Inst)
        data.instructions.push(type);

    function emitConstant(value:Dynamic)
    {
        data.constants.push(value);
        
        emit(data.constants.length - 1);
    }

    function emitConstantPush(value:Dynamic)
    {
        emit(IConstant);

        emitConstant(value);
    }
}