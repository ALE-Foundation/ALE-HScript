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
        return compileCode(() -> {
            for (expr in source)
                emitExpr(expr);
        });

    function compileCode(func:Void -> Void, ?newCode:Code):Code
    {
        final oldCode:Code = code;

        newCode ??= new Code();

        code = newCode;

        func();

        code = oldCode;

        return newCode;
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


            case ETypedef(_):

            case EAlias(id, type):
                emitExpr(type);

                emit(IAlias);

                emitConstant(id);


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


            case EFunction(args, block):
                reverseEach(args, arg -> emitExpr(arg.value));

                emit(IFunction);

                emitConstant(args.length);

                for (arg in args)
                    emitConstant(arg.id);

                emitConstant(switch (block.type)
                {
                    case EBlock(exprs):
                        compileCode(() -> {
                            for (expr in exprs)
                                emitExpr(expr);
                        });

                    default:
                        error(EInvalidExpression(block.type), block);

                        null;
                });


            case EBlock(exprs):
                emit(IBlock);

                emitConstant(compileCode(() -> {
                    for (expr in exprs)
                        emitExpr(expr);
                }));


            case EString(str):
                pushConstant(str);

            case EInterpolatedString(parts):
                reverseEach(parts, part -> emitExpr(part));

                emit(IInterpolatedString);

                emitConstant(parts.length);

            case ENumber(num):
                pushConstant(num);

                
            case EArray(members):
                reverseEach(members, mem -> emitExpr(mem));

                emit(IArray);

                emitConstant(members.length);

            /*
            case EArrayComprehension(body):
            */

            case EMap(members):
                var count:Int = 0;

                for (key => value in members)
                {
                    emitExpr(value);

                    emitExpr(key);

                    count++;
                }

                emit(IMap);

                emitConstant(count);

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
    {
        code.constants.push(value);

        code.instructions.push(code.constants.length - 1);
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