package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class Macros
{
    public static function init()
    {
        Context.onAfterTyping(moduleTypes -> {
            AbstractsMacro.onAfterTyping(moduleTypes);
            EnumsMacro.onAfterTyping(moduleTypes);
            ExtensibleMacro.onAfterTyping(moduleTypes);
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

    public static function isPrivate(type:Type):Bool
        return (switch (type)
        {
            case TMono(ref):
                isPrivate(ref?.get());

            case TEnum(ref, params):
                ref?.get()?.isPrivate || privateParams(params);

            case TInst(ref, params):
                ref?.get()?.isPrivate || privateParams(params);

            case TType(ref, params):
                ref?.get()?.isPrivate || privateParams(params);

            case TFun(args, ret):
                isPrivate(ret) || [for (arg in args) isPrivate(arg.t)].contains(true);

            case TDynamic(type):
                isPrivate(type);

            case TAbstract(ref, params):
                ref?.get()?.isPrivate || privateParams(params);

            case TAnonymous(ref):
                false;
                
            case TLazy(_):
                false;

        }) ?? false;

    public static function privateParams(params:Array<Type>):Bool
    {
        for (par in params)
            if (isPrivate(par))
                return true;

        return false;
    }
}