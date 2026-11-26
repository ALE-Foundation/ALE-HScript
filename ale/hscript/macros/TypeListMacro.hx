package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

import haxe.rtti.Meta;

using StringTools;

@:unreflective
class TypeListMacro
{
    public static var fields(get, null):Map<String, Array<String>>;
    static function get_fields():Map<String, Array<String>>
    {
        if (fields == null)
        {
            fields = [];

            /*
            eachMetaList('fieldsList', entry -> {
                final parts:Array<String> = entry.split('=');

                final field:String = parts.pop();

                final type:String = parts.join('.');

                if (!fields.exists(type))
                    fields[type] = [];

                fields[type].push(field);
            });
            */
        }

        return fields;
    }

    public static var list(get, null):Map<String, Array<String>>;
    static function get_list():Map<String, Array<String>>
    {
        if (list == null)
        {
            list = [];

            eachMetaList('typeList', entry -> {
                final parts:Array<String> = entry.split('.');

                final typeName:String = parts.pop();

                final pack:String = parts.join('.');

                if (!list.exists(pack))
                    list[pack] = [];

                list[pack].push(typeName);
            });
        }

        return list;
    }

    public static var typedefs(get, null):Map<String, Class<Dynamic>>;
    static function get_typedefs():Map<String, Class<Dynamic>>
    {
        if (typedefs == null)
        {
            typedefs = [];

            eachMetaList('typedefList', entry -> {
                final parts:Array<String> = entry.split('=');

                final resolved = std.Type.resolveClass(parts[1]);

                if (resolved != null)
                    typedefs[parts[0]] = resolved;
            });
        }

        return typedefs;
    }

    static function eachMetaList(id:String, call:String -> Void)
    {
        final raw:String = Reflect.getProperty(Meta.getType(TypeListMacro), id)[0];

        if (raw == null)
            return;

        for (entry in raw.split(';'))
        {
            if (entry == null || entry.length <= 0)
                continue;

            call(entry);
        }
    }

    #if macro
    public static function onGenerate(types:Array<Type>)
        switch (Context.getType('ale.hscript.macros.TypeListMacro'))
        {
            case TInst(t, _):
                final cls = t.get();

                if (cls.meta.has('typeList'))
                    return;

                final entries:Array<String> = [];
                final typedefEntries:Array<String> = [];
                final fieldsEntries:Array<String> = [];

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

                                    typedefEntries.push((td.pack.length > 0 ? td.pack.join('.') + '.' : '') + td.name + '=' + (concrete.pack.length > 0 ? concrete.pack.join('.') + '.' : '') + concrete.name);

                                default:
                            }

                        case TInst(ref, _):
                            final c = ref.get();

                            final className:String = (c.pack.length > 0 ? c.pack.join('.') + '.' : '') + c.name;

                            entries.push(className);

                            var curClass = c;

                            while (curClass != null)
                            {
                                for (field in curClass.fields.get())
                                    fieldsEntries.push(className + '=' + field.name);

                                curClass = curClass?.superClass?.t?.get();
                            }

                        default:
                    }
                }

                final lists:Array<Dynamic> = [
                    ['typeList', entries],
                    ['typedefList', typedefEntries],
                    /*
                    ['fieldsList', fieldsEntries]
                    */
                ];

                for (list in lists)
                    cls.meta.add(list[0], [macro $v{list[1].join(';')}], Context.currentPos());

            default:
        }
    #end
}