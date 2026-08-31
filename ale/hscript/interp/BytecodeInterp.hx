package ale.hscript.interp;

import ale.hscript.macros.TypeListMacro;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

import ale.hscript.bytecode.*;

import haxe.Constraints.IMap;
import haxe.ds.GenericStack;
import haxe.ds.ObjectMap;

class BytecodeInterp extends Interp
{
    public function new(?name:String, ?superInstance:Dynamic)
    {
        super(name, superInstance);

        scope.define('trace', Reflect.makeVarArgs(args -> haxe.Log.trace(args.join(','), null)));
    }

    var code:Code;

    var instructions(get, never):Array<Int>;
    inline function get_instructions():Array<Int>
        return code.instructions;

    var constants(get, never):Array<Dynamic>;
    inline function get_constants():Array<Dynamic>
        return code.constants;

    var ip:Int;

    var stack:Array<Dynamic>;

    var callStack:GenericStack<CallFrame>;

    var scopeStack:GenericStack<Scope>;

    public function execute(exprs:Array<Expr>):Dynamic
    {
        code = new Compiler().compile(exprs);

        return interpret();
    }

    public function interpret(?code:Code):Dynamic
    {
        if (code != null)
            this.code = code;

        ip = 0;
        stack = [];
        callStack = new GenericStack<CallFrame>();
        scopeStack = new GenericStack<Scope>();

        while (ip < instructions.length)
            eval(read());

        return null;
    }


    inline function read():Int
        return instructions[ip++];

    inline function constant():Dynamic
        return constants[read()];

    inline function array():Array<Dynamic>
    {
        var count:Int = constant();

        final res:Array<Dynamic> = [];

        while (count-- > 0)
            res.push(pop());

        return res;
    }

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

            case IEnterScope:
                scope = createScope(scope);

            case IExitScope:
                scope = scope.parent;


            case IVarDecl:
                scope.define(constant(), pop(), constant(), constant(), constant());

            case IFunctionDecl:
                scope.define(constant(), pop(), null, PNever, false);


            case IAlias:
                imports[constant()] = pop();
            

            case IVar:
                final id:String = constant();

                push(try
                {
                    scope.get(id);
                } catch(e:ErrorType) {
                    if (superExists(id))
                        Reflect.getProperty(superInstance, id);
                    else if (imports.exists(id))
                        imports[id];
                    else {
                        throw e;

                        null;
                    }
                });

            case IField:
                push(Reflect.getProperty(pop(), constant()));

            case IType:
                push(resolveType(constant()));

            case IArrayAccess:
                final obj:Dynamic = pop();
                final key:Dynamic = pop();

                push(obj is Array ? obj[key] : obj is IMap ? obj.get(key) : null);


            case ICall:
                push(Reflect.callMethod(null, pop(), array()));

            case INew:
                push(Type.createInstance(pop(), array()));

            
            case IFunction:
                var count:Int = constant();

                final args:Array<FunctionArgument> = [];

                while (count-- > 0)
                    args.push({
                        id: constant(),
                        value: pop()
                    });

                final start:Int = constant();
                final end:Int = constant();

                final curScope:Scope = scope;

                push(Reflect.makeVarArgs(uArgs -> {
                    callStack.add({ip: ip, scope: scope});

                    scope = createScope(curScope);

                    for (index => arg in args)
                        scope.define(arg.id, uArgs[index] ?? arg.value);

                    ip = start;

                    while (ip < end)
                        eval(read());

                    return pop();
                }));

            
            case IInterpolatedString:
                final buffer:StringBuf = new StringBuf();

                for (part in array())
                    buffer.add(part);

                push(buffer.toString());


            case IArray:
                push(array());

            case IMap:
                final map:ObjectMap<Dynamic, Dynamic> = new ObjectMap<Dynamic, Dynamic>();

                var count:Int = constant();

                while (count-- > 0)
                    map.set(pop(), pop());

                push(map);

            case IStructure:
                final res:Dynamic = {};

                var count:Int = constant();

                while (count-- > 0)
                    Reflect.setField(res, constant(), pop());

                push(res);

            
            case IAssign:
                push(scope.set(constant(), pop()));

            case IFieldAssign:
                final obj:Dynamic = pop();
                final value:Dynamic = pop();

                Reflect.setProperty(obj, constant(), value);

                push(value);

            case IArrayAssign:
                final obj:Dynamic = pop();
                final key:Dynamic = pop();
                final value:Dynamic = pop();

                if (obj is Array)
                    obj[key] = value;
                else if (obj is IMap)
                    obj.set(key, value);

                push(value);


            case IReturn:
                restoreFromCallStack();


            case ICast:
                final obj:Dynamic = pop();
                final type:Dynamic = pop();

                push(type == null ? obj : Std.downcast(obj, type));

                
            case IPackage:
                softPackage = constant();
                
            case IImport:
                final alias:Null<String> = constant();
                final module:String = constant();

                imports[alias ?? module.split('.').pop()] = resolveType(module, false);

            case IPackageImport:
                final module:String = constant();

                for (type in TypeListMacro.list[module])
                    imports[type] = Type.resolveClass(module + '.' + type);

            case IUsing:
                usings.push(pop());


            case null:
                push(null);

            default:
        }
    }

    inline function restoreFromCallStack()
    {
        final data:CallFrame = callStack.pop();

        ip = data.ip;

        scope = data.scope;
    }
}