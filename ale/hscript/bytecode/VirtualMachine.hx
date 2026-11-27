package ale.hscript.bytecode;

import ale.hscript.parser.Expr;

import ale.hscript.interp.*;

class VirtualMachine extends Interp
{
    var data:CompilerData = null;

    var ip:Int;
    var stack:Array<Dynamic>;

    override function init()
    {
        super.init();

        scope.define('trace', Reflect.makeVarArgs((str:Array<Dynamic>) -> haxe.Log.trace(str.join(','), null)));
    }

    override function execute(exprs:Array<Expr>):Dynamic
    {
        ip = 0;
        stack = [];

        errorHandled(() -> {
            data = new Compiler(exprs).compile();
            
            trace(data);

            while (ip < data.instructions.length)
                byteEval(read());
        });

        return null;
    }

    inline function read():Int
        return data.instructions[ip++];

    inline function constant():Dynamic
        return data.constants[read()];

    inline function push(obj:Dynamic)
        stack.push(obj);

    inline function pop():Dynamic
        return stack.pop();

    function evalExprArray():Array<Dynamic>
    {
        final res:Array<Dynamic> = [];

        for (_ in 0...pop())
            res.unshift(pop());

        return res;
    }

    function evalConstantArray():Array<Dynamic>
        return [
            for (_ in 0...constant())
                constant()
        ];

    // recordatorio para alejito:
    // EXTRAER HACIA ATRÁS RESPETANDO EL ORDEN DE EVALUACIÓN

    function byteEval(inst:Inst)
        switch (inst)
        {
            case IConstant:
                push(constant());

            case IVar:
                push(resolve(constant()));

            case ICall:
                final args = evalExprArray();

                push(Reflect.callMethod(null, pop(), args));

            case IVarDecl:
                define(constant(), pop(), cast evalConstantArray(), constant(), constant(), constant());

            default:
        }
}