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
            pushConstant(null);
         
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

                final end:Int = instructions.length;

                emit(IFunction);

                emitConstant(args.length);

                for (arg in args)
                    emitConstant(arg.id);

                emitConstant(start);
                emitConstant(end);

            case EBlock(exprs):
                emit(IEnterScope);

                for (expr in exprs)
                    emitExpr(expr);

                emit(IExitScope);


            case EString(str):
                pushConstant(str);

            case EInterpolatedString(parts):
                emitArray(parts);

                emit(IInterpolatedString);

                emitConstant(parts.length);

            case ENumber(num):
                pushConstant(num);


            case EArray(members):
                emitArray(members);

                emit(IArray);

                emitConstant(members.length);

            case EMap(members):
                var count:Int = 0;

                for (key => val in members)
                {
                    emitExpr(val);
                    emitExpr(key);

                    count++;
                }

                emit(IMap);

                emitConstant(count);

            case EStructure(values):
                var keys:Array<String> = [];

                var count:Int = 0;

                for (key => value in values)
                {
                    keys.unshift(key);

                    emitExpr(value);

                    count++;
                }

                emit(IStructure);

                emitConstant(count);

                for (key in keys)
                    emitConstant(key);


            case ERegex(reg):
                pushConstant(reg);


            case ETrue:
                pushConstant(true);

            case EFalse:
                pushConstant(false);

            case ENull:
                pushConstant(null);

            
            case EReturn(val):
                emitExpr(val);

                emit(IReturn);
            

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