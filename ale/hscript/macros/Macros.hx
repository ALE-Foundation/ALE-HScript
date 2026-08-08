package ale.hscript.macros;

import haxe.macro.Context;

class Macros
{
    public static function init()
    {
        Context.onAfterTyping(moduleTypes -> {
            AbstractsMacro.onAfterTyping(moduleTypes);
            EnumsMacro.onAfterTyping(moduleTypes);
        });

        Context.onGenerate(types -> {
            TypeListMacro.onGenerate(types);
        });
    }
}