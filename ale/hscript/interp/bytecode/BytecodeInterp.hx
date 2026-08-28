package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

class BytecodeInterp extends BaseInterp
{
    var code:Code;

    var instructions(get, never):Array<Int>;
    inline function get_instructions():Array<Int>
        return code.instructions;

    var constants(get, never):Array<Dynamic>;
    inline function get_constants():Array<Dynamic>
        return code.constants;

    var ip:Int;

    var stack:Array<Dynamic>;

    override function init()
        scope.define('trace', Reflect.makeVarArgs(args -> haxe.Log.trace(args.join(','), null)));

    public function execute(exprs:Array<Expr>):Dynamic
    {
        ip = 0;
        stack = [];

        executeCode(new Compiler().compile(exprs));

        return null;
    }


    function executeScopeCode(newCode:Code, ?newScope:Scope)
    {
        newScope ??= createScope(scope);

        final oldScope:Scope = scope;

        scope = newScope;

        executeCode(newCode);

        scope = oldScope;
    }

    function executeCode(newCode:Code)
    {
        final oldCode:Code = code;
        final oldIP:Int = ip;

        code = newCode;
        ip = 0;

        while (ip < instructions.length)
            eval(read());

        code = oldCode;
        ip = oldIP;
    }


    inline function read():Int
        return instructions[ip++];

    inline function constant():Dynamic
        return constants[read()];

    inline function pop():Dynamic
        return stack.pop();

    inline function push(obj:Dynamic):Dynamic
        return stack.push(obj);

    function eval(inst:Inst, ?newScope:Scope)
    {
        switch (inst)
        {
            case IPush:
                push(constant());


            case IVarDecl:
                scope.define(constant(), pop(), constant(), constant(), constant());

            case IFunctionDecl:
                scope.define(constant(), pop(), PDefault, PNever);


            case IVar:
                push(scope.get(constant()));

            case IField:
                push(Reflect.getProperty(pop(), constant()));

            case IType:
                push(resolveType(constant()));

            case IArrayAccess:
                push(pop()[pop()]);

                
            case ICall:
                final fn = pop();

                var count:Int = constant();

                final args:Array<Dynamic> = [];

                while (count-- > 0)
                    args.push(pop());

                Reflect.callMethod(null, fn, args);


            case IFunction:
                var argCount:Int = constant();

                final args:Array<FunctionArgument> = [];

                while (argCount-- > 0)
                    args.push({
                        id: constant(),
                        value: pop()
                    });

                final code:Code = constant();

                final curScope:Scope = scope;

                push(Reflect.makeVarArgs(useArgs -> {
                    final newScope:Scope = createScope(curScope);

                    for (i => arg in args)
                        newScope.define(arg.id, useArgs[i] ?? arg.value);

                    executeScopeCode(code, newScope);
                }));

            case IBlock:
                executeScopeCode(constant());


            case IArray:
                var count:Int = constant();

                final res:Array<Dynamic> = [];

                while (count-- > 0)
                    res.push(pop());

                push(res);

            case IStructure:
                final length:Int = constant();

                final res:Dynamic = {};

                for (i in 0...length)
                    Reflect.setField(res, constant(), pop());

                push(res);


            case null:
                push(null);

            default:
        }
    }
}