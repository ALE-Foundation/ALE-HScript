package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

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

    public static function getPath(name:String, module:String):TypePath
    {
        final parts = module.split('.');

        if (parts[parts.length - 1] == name)
        {
            parts.pop();

            return {
                pack: parts,
                name: name
            };
        }

        final moduleName = parts.pop();

        return {
            pack: parts,
            name: moduleName,
            sub: name
        };
    }
}