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
                    final abs = ref.get();

                    if (abs.params.length > 0 || abs.impl == null || abs.isPrivate || abs.name == 'XmlType' || abs.module.startsWith('cpp.') || abs.module.startsWith('hxvlc.externs.'))
                        continue;

                    final wrapped:String = '__ale_hscript_abstract_wrapped';
                    
                    final absPath:TypePath = Macros.getPath(abs.name, abs.module);

                    final fields:Array<Field> = [
                        {
                            pos: Context.currentPos(),
                            access: [APublic],
                            name: 'new',
                            kind: FFun({
                                args: [
                                    {
                                        name: 'value',
                                        type: TPath(absPath)
                                    }
                                ],
                                expr: macro {
                                    this.__ale_hscript_abstract_wrapped = value;
                                }
                            })
                        },
                        {
                            pos: Context.currentPos(),
                            access: [APublic, AFinal],
                            name: wrapped,
                            meta: [
                                {
                                    pos: Context.currentPos(),
                                    name: ':unreflective'
                                }
                            ],
                            kind: FVar(TPath(absPath))
                        }
                    ];

                    final name:String = abs.name + SUFFIX;
                    
                    final pack:Array<String> = abs.module.split('.');
                    pack.pop();

                    for (field in abs.impl.get().statics.get())
                    {
                        switch (field.type)
                        {
                            case TAbstract(a, params) if (a.toString() == abs.name):
                                if (params.length > 0)
                                    continue;

                                fields.push({
                                    name: field.name,
                                    access: [APublic, AStatic],
                                    kind: FProp(
                                        'get',
                                        'never',
                                        TPath(absPath)
                                    ),
                                    pos: Context.currentPos()
                                });

                                fields.push({
                                    name: 'get_' + field.name,
                                    access: [AStatic],
                                    kind: FFun({
                                        args: [],
                                        ret: TPath(absPath),
                                        expr: {
                                            pos: Context.currentPos(),
                                            expr: EReturn(
                                                /*
                                                {
                                                    pos: Context.currentPos(),
                                                    expr: ENew(
                                                        {
                                                            pack: pack,
                                                            name: name
                                                        },
                                                        [
                                                        */
                                                            {
                                                                pos: Context.currentPos(),
                                                                expr: EField(
                                                                    {
                                                                        pos: Context.currentPos(),
                                                                        expr: EConst(CIdent(abs.name))
                                                                    },
                                                                    field.name,
                                                                    Normal
                                                                )
                                                            }
                                                        /*
                                                        ]
                                                    )
                                                }
                                                */
                                            )
                                        }
                                    }),
                                    pos: Context.currentPos()
                                });

                            default:
                        }
                    }

                    Context.defineType({
                        pack: pack,
                        name: name,
                        kind: TDClass(
                            null,
                            [
                                {
                                    pack: ['ale', 'hscript', 'macros'],
                                    name: 'AbstractWrapper',
                                    params: [
                                        TPType(TPath(absPath))
                                    ]
                                }
                            ],
                            false,
                            false,
                            false
                        ),
                        fields: fields,
                        pos: Context.currentPos()
                    });

                default:
            }
        }
    }
    #end
}