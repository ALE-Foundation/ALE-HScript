package ale.hscript.macros;

import haxe.macro.TypeTools;
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

                    final pack:Array<String> = abs.module.split('.');
                    pack.pop();

                    final fullPath:Array<String> = abs.module.split('.').concat([abs.name]);

                    final fields:Array<Field> = [];

                    final declared = ['_new'];

                    function defineField(name:String)
                    {
                        try
                        {
                            Context.typeof(macro @:privateAccess $p{fullPath.concat([name])});
                        } catch (e:Dynamic) {
                            return;
                        }
                        
                        declared.push(name);

                        fields.push({
                            access: [APublic, AStatic],
                            pos: pos,
                            name: name,
                            kind: FProp('get', 'never', macro : Dynamic)
                        });

                        fields.push({
                            access: [AStatic],
                            pos: pos,
                            name: 'get_' + name,
                            kind: FFun({
                                ret: macro : Dynamic,
                                args: [],
                                expr: macro @:privateAccess return $p{fullPath.concat([name])}
                            })
                        });
                    }

                    for (field in abs.impl.get().statics.get())
                    {
                        if (declared.contains(field.name) || field.meta.has(':deprecated'))
                            continue;

                        switch (field.kind)
                        {
                            case FVar(g, s):
                                if (g == AccCall)
                                    declared.push('get_' + field.name);

                                if (s == AccCall)
                                    declared.push('set_' + field.name);
                                
                                defineField(field.name);

                            case FMethod(_):
                                defineField(field.name);
                                
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