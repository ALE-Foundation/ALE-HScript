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

        haxe.Log.trace(
            '\nInstructions: ' + instructions + '\n\n' +
            'Constants: ' + constants + '\n'
        , null);

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

            case IVarDecl:
                scope.define(constant(), pop(), constant(), constant(), constant());

            case IVar:
                push(scope.get(constant()));

            case IField:
                push(Reflect.getProperty(pop(), constant()));

            case ICall:
                final fn = pop();

                var count:Int = constant();

                final args:Array<Dynamic> = [];

                while (count-- > 0)
                    args.push(pop());

                Reflect.callMethod(null, fn, args);

            case IStructure:
                final length:Int = constant();

                final res:Dynamic = {};

                for (i in 0...length)
                    Reflect.setField(res, constant(), pop());

                push(res);

            default:
        }
    }
}