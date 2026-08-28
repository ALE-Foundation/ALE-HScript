package ale.hscript.interp.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

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

    override function init()
    {
        scope.define('trace', Reflect.makeVarArgs(args -> haxe.Log.trace(args.join(','), null)));
    }

    public function execute(exprs:Array<Expr>):Dynamic
    {
        compiler = new Compiler().compile(exprs);

        trace(instructions);

        stack = [];

        ip = 0;

        while (ip < instructions.length)
            eval(read());

        return null;
    }

    inline function read():Int
        return instructions[ip++];

    inline function constant():Dynamic
        return constants[read()];

    function eval(inst:Inst)
    {
        switch (inst)
        {
            case CONST:
                stack.push(constant());

            case SET_VAR:
                scope.define(constant(), stack.pop());

            case GET_VAR:
                stack.push(scope.get(constant()));

            case CALL:
                var count:Int = read();

                final args:Array<Dynamic> = [];

                while (count-- > 0)
                    args.unshift(stack.pop());

                Reflect.callMethod(null, stack.pop(), args);

            default:
        }
    }
}