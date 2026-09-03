package ale.hscript.bytecode;

import ale.hscript.errors.ErrorType;
import ale.hscript.errors.Error;

import ale.hscript.utils.Util;

import ale.hscript.parser.Expr;

class Compiler
{
    public function new() {}

    public final instructions:Array<Int> = [];

    public final constants:Array<Dynamic> = [];
    
    public function compile(exprs:Array<Expr>):Code
    {
        instructions.resize(0);
        constants.resize(0);

        for (expr in exprs)
            emitStatement(expr);

        return {
            instructions: instructions,
            constants: constants
        };
    }

    function emitStatement(expr:Expr)
    {
        emitExpr(expr);

        if (!isVoidExpr(expr))
            emit(IPop);
    }

    function isVoidExpr(expr:Expr):Bool
    {
        if (expr == null)
            return false;

        return switch (expr.type)
        {
            case EVarDecl(_, _, _, _, _), EFunctionDecl(_, _), ETypedef(_, _), EAlias(_, _), EPackage(_), EImport(_, _), EPackageImport(_), EUsing(_), EEof:
                true;

            default:
                false;
        }
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
                emitExpr(obj);
                emitExpr(key);

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
                for (arg in args)
                    emitExpr(arg.value);

                final jump:Int = emitJump();

                final start:Int = instructions.length;

                emitExpr(body);

                emitJumpExit();

                final end:Int = instructions.length;

                patchJump(jump);

                emit(IFunction);

                emitConstant(args.length);

                reverseEach(args, arg -> emitConstant(arg.id));

                emitConstant(start);
                emitConstant(end);

            case EBlock(exprs):
                emit(IEnterScope);

                for (expr in exprs)
                    emitStatement(expr);

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
                    emitExpr(key);
                    emitExpr(val);

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


            case EAssign(obj, value):                
                switch (obj.type)
                {
                    case EVar(id):
                        emitExpr(value);

                        emit(IAssign);

                        emitConstant(id);

                    case EField(obj, prop):
                        emitExpr(obj);
                        emitExpr(value);

                        emit(IFieldAssign);

                        emitConstant(prop);

                    case EArrayAccess(obj, key):
                        emitExpr(obj);
                        emitExpr(key);
                        emitExpr(value);

                        emit(IArrayAssign);

                    default:
                        error(EInvalidAssignment, expr);
                }


            case EBinOp(op, left, right):
                final opVal:Operator = Util.tokenTypeToOperator(op);

                emitExpr(left);

                final jumpIndex:Null<Int> = switch (opVal)
                {
                    case ODoubleAmpersand:
                        emitConditionalJump(true, IInverseConditionalJump);

                    case ODoublePipe:
                        emitConditionalJump(true);

                    case ODoubleQuestion:
                        emitConditionalJump(null, IInverseConditionalJump);

                    default:
                        null;
                }

                emitExpr(right);

                if (jumpIndex != null)
                    patchJump(jumpIndex);

                emit(IBinOp);

                emitConstant(opVal);

            
            case EReturn(val):
                emitExpr(val);

                emit(IReturn);


            case ECast(obj, type):
                emitExpr(type);
                emitExpr(obj);

                emit(ICast);


            case EPackage(module):
                emit(IPackage);

                emitConstant(module);

            case EImport(module, alias):
                emit(IImport);

                emitConstant(alias);
                emitConstant(module);

            case EPackageImport(module):
                emit(IPackageImport);

                emitConstant(module);

            case EUsing(module):
                emitExpr(module);

                emit(IUsing);


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

    function emitConditionalJump(val:Dynamic, ?type:Inst = IConditionalJump):Int
    {
        emit(type);

        emitConstant(val);

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
        for (expr in arr)
            emitExpr(expr);
        

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