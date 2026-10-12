package ale.hscript.macros;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class ExtensibleMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Extensible';
    public static final SUPER_SUFFIX:String = '_ALE_HScript_super';
    public static final INSTANCE:String = '_ALE_HScript_Sripted';

    macro public static function build():Array<Field>
    {
        final baseClass = Context.getLocalClass().get();

        final ogFields = Context.getBuildFields();

        var totalArgs:Null<Int> = null;

        for (field in ogFields)
            switch (field.kind)
            {
                case FFun(func):
                    if (field.name != 'new')
                        continue;

                    totalArgs = func.args.length;

                    break;

                default:
            }

        final baseFields = [];

        final names = new Map<String, Bool>();

        final classes:Array<ClassType> = [baseClass];

        var sup = baseClass.superClass.t.get();

        while (sup != null)
        {
            classes.push(sup);

            sup = sup.superClass?.t.get();
        }

        for (cls in classes)
        {
            for (field in cls.fields.get())
                if (!names.exists(field.name))
                {
                    baseFields.push(field);

                    names[field.name] = true;
                }

            if (totalArgs == null || cls.constructor != null)
                switch (cls.constructor?.get().type)
                {
                    case TLazy(func):
                        switch (func())
                        {
                            case TFun(args, _):
                                totalArgs = args.length;

                            default:
                        }

                    default:
                }
        }

        final extensibleFields:Array<Field> = [{
            pos: Context.currentPos(),
            name: INSTANCE,
            kind: FVar(macro:ale.hscript.interp.ScriptedInstance<Dynamic>),
            access: [AFinal]
        }];

        if (totalArgs != null)
        {
            var superArgs:Array<Expr> = [for (i in 0...totalArgs) macro cast localArgs[$v{i}]];

            extensibleFields.push({
                pos: Context.currentPos(),
                name: 'new',
                kind: FFun({
                    args: [
                        {
                            name: 'instance',
                            type: macro:ale.hscript.interp.ScriptedInstance<Dynamic>
                        },
                        {
                            name: 'args',
                            type: macro:Array<Dynamic>
                        }
                    ],
                    expr: macro {
                        var localArgs = args;

                        final consData = instance.scope.constructorData;

                        if (consData != null)
                        {
                            consData.initScope(args);
                            consData.initPre();
                            
                            localArgs = consData.getSuperArgs();
                        }
                        
                        super($a{superArgs});

                        if (consData != null)
                        {
                            consData.initPost();
                            consData.destroyScope();
                        }

                        $i{INSTANCE} = instance;

                        $i{INSTANCE}.nativeExtension = this;
                    }
                })
            });
        }

        for (field in baseFields)
        {
            final fieldName = field.name;

            switch (field.type)
            {
                case TLazy(lazy):
                    switch (lazy())
                    {
                        case TFun(funcArgs, ret):
                            final call:Expr = {
                                expr: ECall({
                                    expr: EField(macro super, fieldName),
                                    pos: Context.currentPos()
                                }, [for (a in funcArgs) macro $i{a.name}]),
                                pos: Context.currentPos()
                            };

                            final fixedArgs = [
                                for (arg in funcArgs)
                                    {
                                        name: arg.name,
                                        type: Context.toComplexType(arg.t)
                                    }
                            ];

                            final isVoid:Bool = switch (Context.toComplexType(ret))
                            {
                                case TPath({name: 'Void', pack: []}):
                                    true;

                                default:
                                    false;
                            }

                            extensibleFields.push({
                                pos: Context.currentPos(),
                                name: fieldName + SUPER_SUFFIX,
                                kind: FFun({
                                    args: fixedArgs.copy(),
                                    ret: Context.toComplexType(ret),
                                    expr: isVoid ? call : macro return $call
                                })
                            });

                            var argExprs:Array<Expr> = [for (i in 0...fixedArgs.length) macro $i{'arg' + i}];

                            extensibleFields.push({
                                pos: Context.currentPos(),
                                name: fieldName,
                                access: [AOverride],
                                kind: FFun({
                                    args: [for (i => arg in fixedArgs) {
                                        name: 'arg' + i,
                                        type: arg.type
                                    }],
                                    ret: Context.toComplexType(ret),
                                    expr: isVoid ? macro {
                                        if ($i{INSTANCE}.scope.exists($v{fieldName}, false))
                                            Reflect.callMethod(this, $i{INSTANCE}.get($v{fieldName}), [$a{argExprs}]);
                                        else
                                            super.$fieldName($a{argExprs});
                                    } : macro {
                                        if ($i{INSTANCE}.scope.exists($v{fieldName}, false))
                                            return Reflect.callMethod(this, $i{INSTANCE}.get($v{fieldName}), [$a{argExprs}]);

                                        return super.$fieldName($a{argExprs});
                                    }
                                })
                            });

                        default:
                    }
                default:
            }
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

        return Context.getBuildFields();
    }
}