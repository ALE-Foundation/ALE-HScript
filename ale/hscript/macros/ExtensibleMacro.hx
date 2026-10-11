package ale.hscript.macros;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class ExtensibleMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Extensible';
    public static final FIELD_SUFFIX:String = '_ALE_HScript_super';

    macro public static function build():Array<Field>
    {
        final baseClass = Context.getLocalClass().get();
        final baseFields = Context.getBuildFields();

        final extensibleFields:Array<Field> = [];

        for (field in baseFields)
            switch (field.kind)
            {
                case FFun(func):
                    if (field.access.contains(AStatic))
                        continue;

                    if (field.name == 'new')
                    {
                        var superArgs:Array<Expr> = [for (i in 0...func.args.length) macro cast args[$v{i}]];

                        extensibleFields.push({
                            pos: Context.currentPos(),
                            name: 'new',
                            kind: FFun({
                                args: [
                                    {
                                        name: 'cls',
                                        type: macro:ale.hscript.interp.ScriptedInstance<Dynamic>
                                    },
                                    {
                                        name: 'args',
                                        type: macro:Array<Dynamic>
                                    }
                                ],
                                expr: macro {
                                    super($a{superArgs});
                                }
                            })
                        });

                        continue;
                    }

                    final call:Expr = {
                        expr: ECall({
                            expr: EField(macro super, field.name),
                            pos: Context.currentPos()
                        }, [for (a in func.args) macro $i{a.name}]),
                        pos: Context.currentPos()
                    };

                    extensibleFields.push({
                        pos: Context.currentPos(),
                        name: field.name + FIELD_SUFFIX,
                        kind: FFun({
                            args: func.args?.copy(),
                            params: func.params?.copy(),
                            ret: func.ret,
                            expr: switch (func.ret)
                            {
                                case TPath({name: 'Void', pack: []}):
                                    call;

                                default:
                                    macro return $call;
                            }
                        })
                    });

                    extensibleFields.push({
                        pos: Context.currentPos(),
                        name: field.name,
                        access: [AOverride],
                        kind: FFun({
                            args: func.args?.copy(),
                            ret: func.ret,
                            params: func.params?.copy(),
                            expr: macro return null
                        })
                    });

                default:
            }

        Context.defineType({
            pack: baseClass.pack,
            name: baseClass.name + SUFFIX,
            pos: Context.currentPos(),
            kind: TDClass({
                pack: baseClass.pack,
                name: baseClass.name
            }, [{
                pack: ['ale', 'hscript', 'macros'],
                name: 'NativeExtensible'
            }], false, false, false),
            fields: extensibleFields
        });

        return baseFields;
    }
}