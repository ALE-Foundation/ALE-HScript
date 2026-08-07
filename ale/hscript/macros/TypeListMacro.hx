package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

import haxe.rtti.Meta;

using StringTools;

/**
 * Author: Kriptel
 * 
 * @see https://github.com/Kriptel/RuleScript/blob/dev/rulescript/macro/TypeListMacro.hx
 */

class TypeListMacro
{
    public static var list(get, null):Map<String, Array<String>>;

    static function get_list():Map<String, Array<String>>
    {
        if (list == null)
        {
            list = [];

            var raw:String = Meta.getType(ale.hscript.macros.TypeListMacro).typeList[0];

            for (entry in raw.split(';'))
            {
                if (entry == null || entry == '')
                    continue;

                var parts = entry.split('.');
                var typeName = parts.pop();
                var pack = parts.join('.');

                if (!list.exists(pack))
                    list[pack] = [];

                list[pack].push(typeName);
            }
        }

        return list;
    }

    #if macro
    public static function onGenerate(types:Array<Type>)
    {
        switch (Context.getType('ale.hscript.macros.TypeListMacro'))
        {
            case TInst(t, _):
                final cls = t.get();

                if (cls.meta.has('typeList'))
                    return;

                final entries = [];

                for (type in types)
                {
                    switch (type)
                    {
                        case TInst(ref, _):
                            final c = ref.get();

                            final fullName = (c.pack.length > 0 ? c.pack.join('.') + '.' : '') + c.name;

                            if (!fullName.endsWith('_Fields_') && !fullName.endsWith('_Impl_'))
                                entries.push(fullName);

                        default:
                    }
                }

                cls.meta.add('typeList', [macro $v{entries.join(';')}], Context.currentPos());

            default:
        }
    }
    #end
}