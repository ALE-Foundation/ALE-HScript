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