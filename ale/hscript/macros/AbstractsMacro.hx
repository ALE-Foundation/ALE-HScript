package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class AbstractsMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Abstract';

    #if macro
    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (type in types)
        {
            switch (type)
            {
                case TAbstract(ref):
                    final abs:AbstractType = ref.get();

                    if (abs.params.length > 0 || abs.impl == null || abs.isPrivate || abs.name == 'XmlType' || abs.meta.has(':native') || abs.meta.has(':extern') || abs.impl.get().meta.has(':native'))
                        continue;

                    final pos:Position = Context.currentPos();

                    final absPath:TypePath = Macros.getPath(abs.name, abs.module);

                    final pack:Array<String> = abs.module.split('.');
                    pack.pop();

                    final fullPath:Array<String> = abs.module.split('.').concat([abs.name]);

                    final fields:Array<Field> = [];

                    for (field in abs.impl.get().statics.get())
                    {
                        if (!field.isPublic || field.meta.has(':impl'))
                            continue;

                        switch (field.kind)
                        {
                            case FVar(AccNormal | AccInline, _):

                            default:
                                continue;
                        }

                        switch (Context.follow(field.type))
                        {
                            case TAbstract(a, params) if (params.length == 0 && a.get().name == abs.name && a.get().module == abs.module):
                                fields.push({
                                    pos: pos,
                                    name: field.name,
                                    access: [APublic, AStatic],
                                    kind: FProp('get', 'never', TPath(absPath))
                                });

                                fields.push({
                                    pos: pos,
                                    name: 'get_' + field.name,
                                    access: [AStatic],
                                    meta: [{name: ':keep', pos: pos}],
                                    kind: FFun({
                                        args: [],
                                        ret: TPath(absPath),
                                        expr: macro return $p{fullPath.concat([field.name])}
                                    })
                                });

                            default:
                        }
                    }
                    
                    Context.defineType({
                        pack: pack,
                        name: abs.name + SUFFIX,
                        meta: [{name: ':keep', pos: pos}],
                        kind: TDClass(null, [], false, false, false),
                        fields: fields,
                        pos: pos
                    });

                default:
            }
        }
    }
    #end
}