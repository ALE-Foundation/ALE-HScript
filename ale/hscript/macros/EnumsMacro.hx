package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class EnumsMacro
{
    public static final PREFIX:String = 'ALE_HScript_Enum_';

    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (type in types)
        {
            switch (type)
            {
                case TEnumDecl(ref):
                    final enumDecl = ref.get();

                    if (enumDecl.params.length > 0 || enumDecl.module.split('.').pop() != enumDecl.name)
                        continue;

                    final fields:Array<Field> = [];

                    for (key => val in enumDecl.constructs)
                    {
                        if (val.params.length > 0)
                            continue;

                        if (val.name != 'EInvalidCast')
                            continue;

                        switch (val.type)
                        {
                            default:
                                fields.push({
                                    name: val.name,
                                    access: [APublic, AStatic],
                                    kind: FVar(
                                        Context.toComplexType(TEnum(ref, [])),
                                        macro $p{enumDecl.pack.concat([enumDecl.name, val.name])}
                                    ),
                                    pos: val.pos
                                });
                        }
                    }

                    final name:String = PREFIX + enumDecl.name;

                    Context.defineType(
                        {
                            pack: enumDecl.module.replace(enumDecl.name, name).split('.'),
                            name: name,
                            kind: TDClass(null, [], false, true, false),
                            fields: fields,
                            pos: Context.currentPos()
                        }
                    );

                default:
            }
        }
    }
}