package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

import haxe.Constraints.IMap;
import haxe.ds.GenericStack;
import haxe.ds.ObjectMap;

class BytecodeInterp extends BaseInterp
{
    var compiler:Compiler;

    var instructions(get, never):Array<Int>;
    inline function get_instructions():Array<Int>
        return compiler.instructions;

    var constants(get, never):Array<Dynamic>;
    inline function get_constants():Array<Dynamic>
        return compiler.constants;

    var ip:Int;

    var stack:Array<Dynamic>;

    var callStack:GenericStack<CallFrame>;

    override function init()
        scope.define('trace', Reflect.makeVarArgs(args -> haxe.Log.trace(args.join(','), null)));

    public function execute(exprs:Array<Expr>):Dynamic
    {
        compiler = new Compiler().compile(exprs);
        
        ip = 0;
        stack = [];
        callStack = new GenericStack<CallFrame>();

        while (ip < instructions.length)
            eval(read());

        return null;
    }


    inline function read():Int
        return instructions[ip++];

    inline function constant():Dynamic
        return constants[read()];

    inline function pop():Dynamic
        return stack.pop();

    inline function push(obj:Dynamic):Dynamic
        return stack.push(obj);
    

    function eval(inst:Inst)
    {
        switch (inst)
        {
            case IPush:
                push(constant());

            case IJump:
                ip = constant();

            case IExit:
                final frame:CallFrame = callStack.pop();

                ip = frame.ip;
                scope = frame.scope;


            case IVarDecl:
                scope.define(constant(), pop(), constant(), constant(), constant());

            case IFunctionDecl:
                scope.define(constant(), pop(), PDefault, PNever);

            
            case IAlias:
                imports[constant()] = pop();


            case IVar:
                push(scope.get(constant()));

            case IField:
                push(Reflect.getProperty(pop(), constant()));

            case IType:
                push(resolveType(constant()));

            case IArrayAccess:
                final obj:Dynamic = pop();

                final key:Dynamic = pop();

                push(
                    if (Std.isOfType(obj, Array))
                        obj[key]
                    else if (Std.isOfType(obj, IMap))
                        cast(obj, IMap<Dynamic, Dynamic>).get(key)
                    else {
                        null;
                    }
                );

                
            case ICall:
                final fn = pop();

                var count:Int = constant();

                final args:Array<Dynamic> = [];

                while (count-- > 0)
                    args.push(pop());

                Reflect.callMethod(null, fn, args);

            case INew:
                final type:Class<Dynamic> = pop();

                var count:Int = constant();

                final args:Array<Dynamic> = [];

                while (count-- > 0)
                    args.push(pop());

                push(Type.createInstance(type, args));


            case IFunction:
                final start:Int = constant();

                var argCount:Int = constant();

                final args:Array<FunctionArgument> = [];

                while (argCount-- > 0)
                    args.push({
                        id: constant(),
                        value: pop()
                    });
                    

                final capturedScope:Scope = scope;

                push(Reflect.makeVarArgs((uArgs) -> {
                    callStack.add({ip: ip, scope: scope});

                    scope = createScope(new Scope(capturedScope));

                    for (index => arg in args)
                        scope.define(arg.id, uArgs[index] ?? arg.value);

                    ip = start;
                }));

            case IEnterScope:
                scope = createScope(new Scope(scope));

            case IExitScope:
                scope = scope.parent;


            case IInterpolatedString:
                final res:StringBuf = new StringBuf();

                var count:Int = constant();

                while (count-- > 0)
                    res.add(pop());

                push(res.toString());


            case IArray:
                var count:Int = constant();

                final res:Array<Dynamic> = [];

                while (count-- > 0)
                    res.push(pop());

                push(res);

            /*
            case IArrayComprehension:
            */

            case IMap:
                var count:Int = constant();

                final res:ObjectMap<Dynamic, Dynamic> = new ObjectMap();

                while (count-- > 0)
                    res.set(pop(), pop());

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