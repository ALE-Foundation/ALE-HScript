package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

import haxe.rtti.Meta;

using StringTools;

@:unreflective
class TypeListMacro
{
    public static var list(get, null):Map<String, Array<String>>;
    static function get_list():Map<String, Array<String>>
    {
        if (list == null)
        {
            list = [];

            var raw:String = Meta.getType(TypeListMacro).typeList[0];

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

    public static var typedefs(get, null):Map<String, Class<Dynamic>>;
    static function get_typedefs():Map<String, Class<Dynamic>>
    {
        if (typedefs == null)
        {
            typedefs = [];

            var raw:String = Meta.getType(TypeListMacro).typedefList[0];

            for (entry in raw.split(';'))
            {
                if (entry == null || entry == '')
                    continue;

                var parts = entry.split('=');

                if (parts.length < 2)
                    continue;

                var resolved = std.Type.resolveClass(parts[1]);

                if (resolved != null)
                    typedefs[parts[0]] = resolved;
            }
        }

        return typedefs;
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

                final entries:Array<String> = [];
                final typedefEntries:Array<String> = [];

                for (type in types)
                {
                    switch (type)
                    {
                        case TType(ref, _):
                            final td = ref.get();

                            switch (td.type)
                            {
                                case TInst(classRef, _):
                                    final concrete = classRef.get();

                                    typedefEntries.push(
                                        (td.pack.length > 0 ? td.pack.join('.') + '.' : '') + td.name
                                        + '=' +
                                        (concrete.pack.length > 0 ? concrete.pack.join('.') + '.' : '') + concrete.name
                                    );

                                default:
                            }

                        case TInst(ref, _):
                            final c = ref.get();

                            final fullName = (c.pack.length > 0 ? c.pack.join('.') + '.' : '') + c.name;

                            if (!fullName.endsWith('_Fields_') && !fullName.endsWith('_Impl_'))
                                entries.push(fullName);

                        default:
                    }
                }

                cls.meta.add('typeList', [macro $v{entries.join(';')}], Context.currentPos());
                cls.meta.add('typedefList', [macro $v{typedefEntries.join(';')}], Context.currentPos());

            default:
        }
    }
    #end
}