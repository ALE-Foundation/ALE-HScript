package ale.hscript.serialization;

import ale.hscript.bytecode.Code;

import ale.hscript.Config;

import haxe.io.Bytes;

class Unserializer
{
    final source:Bytes;

    public function new(script:String)
    {
        final path:String = Config.SCRIPT_PATH + script + Config.COMPILED_EXTENSION;

        if (Config.FILE_CHECKER(path))
            source = Config.BYTES_READER(path);
        else
            throw '[ MISSING FILE ] ' + path;
    }

    var position:Int = 0;

    public function unserialize():Code
    {
        position = 0;

        if (source.getString(0, 6) != 'ALEHXC')
            throw 'Invalid format';

        position += 6;

        
        var count:Int = 0;


        final constants:Array<Dynamic> = [];

        count = readInt32();

        while (count-- > 0)
            constants.push(switch (readByte())
            {
                case ConstantType.CNull:
                    null;

                case ConstantType.CBool:
                    readByte() != 0;

                case ConstantType.CInt:
                    readInt32();

                case ConstantType.CFloat:
                    final value:Float = source.getFloat(position);

                    position += 4;

                    value;

                case ConstantType.CString:
                    final length:Int = readInt32();

                    final value:String = source.getString(position, length);

                    position += length;

                    value;

                default:
                    throw 'Unsupported constant type';
            });


        final instructions:Array<Int> = [];

        count = readInt32();

        while (count-- > 0)
            instructions.push(readInt32());


        return {
            constants: constants,
            instructions: instructions
        };
    }

    inline function readByte():Int
        return source.get(position++);

    inline function readInt32():Int
    {
        final value:Int = source.getInt32(position);

        position += 4;

        return value;
    }
}