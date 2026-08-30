package ale.hscript.serialization;

import ale.hscript.bytecode.Compiler;

import ale.hscript.parser.Property;
import ale.hscript.parser.Parser;

import ale.hscript.lexer.Lexer;

import ale.hscript.utils.Util;

import haxe.io.BytesBuffer;
import haxe.io.Bytes;

class Serializer
{
    public final source:String;

    public final name:String;

    public final compiledPath:String;

    public function new(script:String, ?name:String)
    {
        final data = Util.resolveScript(script, name);

        this.source = data.source;
        this.name = data.name;
        this.compiledPath = data.compiledPath;
    }

    var compiler:Compiler;

    public function compile()
        compiler = new Compiler().compile(new Parser(new Lexer(source).tokenize()).parse());

    var bytes:Bytes;

    public function serialize()
    {
        if (compiler == null)
            compile();

        final buffer:BytesBuffer = new BytesBuffer();

        buffer.addString('ALEHXC');

        buffer.addInt32(compiler.constants.length);

        for (const in compiler.constants)
            switch (Type.typeof(const))
            {
                case TNull:
                    buffer.addByte(ConstantType.CNull);

                case TBool:
                    buffer.addByte(ConstantType.CBool);
                    buffer.addByte(const ? 1 : 0);

                case TInt:
                    buffer.addByte(ConstantType.CInt);
                    buffer.addInt32(const);
                    
                case TFloat:
                    buffer.addByte(ConstantType.CFloat);
                    buffer.addFloat(const);

                case TClass(_) if (const is String):
                    buffer.addByte(ConstantType.CString);

                    final stringBytes:Bytes = Bytes.ofString(const);

                    buffer.addInt32(stringBytes.length);
                    buffer.addBytes(stringBytes, 0, stringBytes.length);
                    
                default:
                    throw 'Unsupported constant type';
            }

        buffer.addInt32(compiler.instructions.length);

        for (inst in compiler.instructions)
            buffer.addInt32(inst);

        bytes = buffer.getBytes();
    }

    public function save()
    {
        if (bytes == null)
            serialize();

        #if sys
        sys.io.File.saveBytes(compiledPath, bytes);
        #end
    }
}