package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Type;

#if macro
class Macros
{
    public static function init()
    {
        EnumsMacro.init();

        Context.onGenerate(types -> {
            TypeListMacro.onGenerate(types);
        });
    }
}
#end