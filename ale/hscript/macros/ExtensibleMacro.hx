
package ale.hscript.macros;

import ale.hscript.MacrosConfig;

import haxe.macro.TypeTools;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

#if ALE_HS_CLASSES
class ExtensibleMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Extensible';
    public static final SUPER_SUFFIX:String = '_ALE_HScript_super';
    static final RESOLVE:String = '_ALE_HSCRIPT_ResolveField';
    static final SET:String = '_ALE_HSCRIPT_SetField';
    static final LIST:String = '_ALE_HScript_Fields';

    #if macro
    static final ACCESORS:String = '_ALE_HSCRIPT_AccessorsBypass';
    static final INSTANCE:String = '_ALE_HScript_Scripted';
    static final ARGUMENT:String = '_ALE_HSCRIPT_ARGUMENT';

    public static function init()
        Compiler.addGlobalMetadata(
            '',
            '@:build(ale.hscript.macros.ExtensibleMacro.saveImports())',
            true,
            true
        );

    static final imports:Map<String, Array<ImportExpr>> = [];

    public static function saveImports():Array<Field>
    {
        imports[Context.getLocalModule()] = Context.getLocalImports();

        return null;
    }

    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (moduleType in types)
            switch (moduleType)
            {
                case TClassDecl(clsRef):                    
                    final type:ClassType = clsRef.get();

                    if (type.meta.has(':ALE_HS_IGNORE') || (type.params.length > 0 && (type.meta.has(':genericBuild') || type.meta.has(':generic'))) || type.isExtern || type.isAbstract || type.isFinal || type.isInterface || type.isPrivate || type.meta.has(':nativeGen') || type.meta.has(':native') || type.meta.has(':include') || type.meta.has(':structInit') || type.name.endsWith(AbstractsMacro.SUFFIX) || type.name.endsWith(EnumsMacro.SUFFIX) || type.name.endsWith(SUFFIX))
                        continue;

                    var shouldContinue:Bool = false;

                    for (par in type.params)
                        switch(par.t)
                        {
                            case TInst(ref, _):
                                if (par.name == 'Const' || ref.get().meta.has(':const'))
                                    shouldContinue = true;

                            default:
                        }

                    if (shouldContinue)
                        continue;
                    
                    final path:Array<String> = type.pack.concat([type.name]);
                    
                    final joinPath:String = path.join('.');

                    var shouldContinue:Bool = false;

                    for (ignore in MacrosConfig.CLASSES_IGNORE)
                        if (joinPath.startsWith(ignore))
                        {
                            shouldContinue = true;

                            break;
                        }

                    if (shouldContinue)
                        continue;

                    var classes:Array<ClassType> = [];

                    var curClass:ClassType = type;

                    var shouldContinue:Bool = false;

                    var typeImports:Array<ImportExpr> = [];

                    while (curClass != null)
                    {
                        if (curClass.isPrivate)
                        {
                            shouldContinue = true;

                            break;
                        }

                        classes.push(curClass);

                        typeImports = typeImports.concat(imports[curClass.module] ?? []);
                        
                        curClass = curClass.superClass?.t?.get();
                    }

                    if (shouldContinue)
                        continue;

                    var constructor:ClassField = null;

                    for (cls in classes)
                        if ((constructor = cls.constructor?.get()) != null)
                            break;

                    if (constructor == null)
                        continue;

                    final typeParamMap:Map<String, Type> = [];

                    function applyParams(t:Type):Type
                        return switch (t)
                        {
                            case TInst(ref, _):
                                final c:ClassType = ref.get();

                                switch (c.kind)
                                {
                                    case KTypeParameter(constraints):
                                        typeParamMap.get(ref.toString()) ?? (constraints.length > 0 ? applyParams(constraints[0]) : TDynamic(null));

                                    default:
                                        TypeTools.map(t, applyParams);
                                }

                            case null:
                                null;

                            default:
                                TypeTools.map(t, applyParams);
                        }

                    for (p in type.params)
                        switch (p.t)
                        {
                            case TInst(ref, _):
                                typeParamMap.set(ref.toString(), TDynamic(null));

                            default:
                        }

                    for (i in 0...classes.length - 1)
                    {
                        final sup = classes[i].superClass;
                        final declared = sup.t.get().params;

                        for (j => concrete in sup.params)
                            switch (declared[j].t)
                            {
                                case TInst(ref, _):
                                    typeParamMap.set(ref.toString(), applyParams(concrete));

                                default:
                            }
                    }

                    final constructorArgs:Int = switch (constructor.type)
                    {
                        case TFun(args, _):
                            args.length;

                        default:
                            -1;
                    }

                    final constructorDefaults:Array<Null<Expr>> = [for (_ in 0...constructorArgs) null];

                    switch (constructor.expr()?.expr)
                    {
                        case TFunction(func):
                            for (i => arg in func.args)
                                if (arg.value != null)
                                    constructorDefaults[i] = Context.getTypedExpr(arg.value);

                        default:
                    }

                    final superArgs:Array<Expr> = [
                        for (i => def in constructorDefaults)
                            def == null ? macro cast localArgs[$v{i}]: macro cast (localArgs[$v{i}] ?? $e{def})
                    ];

                    final list:Map<String, Bool> = [];

                    final getters:Map<String, String> = [];
                    final setters:Map<String, String> = [];

                    for (fieldsClass in classes)
                        for (field in fieldsClass.fields.get())
                        {
                            if (list.exists(field.name))
                                continue;

                            list[field.name] = true;

                            switch (field.kind)
                            {
                                case FVar(get, set):
                                    switch ([get, set])
                                    {
                                        case [AccCall | AccNever, AccCall | AccNever]:
                                            if (!field.meta.has(':isVar'))
                                                continue;

                                        default:
                                    }

                                    if (get == AccCall)
                                        getters['get_' + field.name] = field.name;

                                    if (set == AccCall)
                                        setters['set_' + field.name] = field.name;

                                case FMethod(MethNormal):
                                    list[field.name + SUPER_SUFFIX] = true;

                                default:
                            }
                        }

                    final fields:Array<Field> = [
                        {
                            pos: Context.currentPos(),
                            name: LIST,
                            access: [AFinal, APublic],
                            kind: FVar(macro : Map<String, Bool>, macro $v{list})
                        },
                        {
                            pos: Context.currentPos(),
                            name: ACCESORS,
                            access: [AFinal, APublic],
                            kind: FVar(macro : Map<String, Bool>, macro [])
                        },
                        {
                            pos: Context.currentPos(),
                            name: INSTANCE,
                            access: [APublic],
                            kind: FVar(macro : ale.hscript.interp.ScriptedInstance)
                        },
                        {
                            pos: Context.currentPos(),
                            name: RESOLVE,
                            access: [APublic],
                            kind: FFun({
                                ret: macro : Dynamic,
                                args: [
                                    {
                                        name: 'id',
                                        type: macro : String
                                    }
                                ],
                                expr: macro {
                                    return $i{INSTANCE}?.get(id) ?? Reflect.getProperty(this, id);
                                }
                            })
                        },
                        {
                            pos: Context.currentPos(),
                            name: SET,
                            access: [APublic],
                            kind: FFun({
                                ret: macro : Dynamic,
                                args: [
                                    {
                                        name: 'id',
                                        type: macro : String
                                    },
                                    {
                                        name: 'value',
                                        type: macro : Dynamic
                                    }
                                ],
                                expr: macro {
                                    return $i{INSTANCE}?.set(id, value) ?? {
                                        Reflect.setProperty(this, id, value);


                                        value;
                                    };
                                }
                            })
                        },
                        {
                            pos: Context.currentPos(),
                            name: 'new',
                            kind: FFun({
                                args: [
                                    {
                                        name: 'instance',
                                        type: macro : ale.hscript.interp.ScriptedInstance
                                    },
                                    {
                                        name: 'args',
                                        type: macro : Array<Dynamic>
                                    }
                                ],
                                expr: macro {
                                    args ??= [];

                                    $i{INSTANCE} = instance;

                                    instance.nativeInstance = instance._this = this;

                                    instance.preConstructor(args);

                                    var localArgs = instance.constructorArgs() ?? args;

                                    super($a{superArgs});

                                    instance.postConstructor();
                                }
                            })
                        }
                    ];

                    final fieldsList:Array<String> = ['new'];

                    for (fieldsClass in classes)
                        for (field in fieldsClass.fields.get())
                        {
                            if (field.params.length > 0 || field.isFinal || field.meta.has(':ALE_HS_IGNORE') || field.meta.has(':generic') || field.meta.has(':inline') || fieldsList.contains(field.name))
                                continue;

                            fieldsList.push(field.name);

                            switch (field.kind)
                            {
                                case FMethod(MethNormal):

                                default:
                                    continue;
                            }

                            final typedExpr = field.expr();

                            if (typedExpr == null)
                                continue;

                            switch (Context.follow(field.type))
                            {
                                case TFun(args, ret):
                                    final name:String = field.name;

                                    final isVoid:Bool = switch (Context.follow(ret))
                                    {
                                        case TAbstract(ref, _):
                                            ref.get().name == 'Void';

                                        default:
                                            false;
                                    }

                                    var shouldContinue:Bool = false;

                                    for (arg in args)
                                        if (Macros.isPrivate(arg.t))
                                        {
                                            shouldContinue = true;

                                            break;
                                        }

                                    if (Macros.isPrivate(ret))
                                        shouldContinue = true;

                                    function makeComplex(t:Type):ComplexType
                                        return t == null ? null : Context.toComplexType(applyParams(t));

                                    final arguments = [];

                                    switch (typedExpr.expr)
                                    {
                                        case TFunction(func):
                                            for (i => arg in func.args)
                                                arguments.push({
                                                    name: arg.v.name + i + ARGUMENT,
                                                    type: makeComplex(arg.v.t),
                                                    opt: args[i].opt && arg.value == null,
                                                    value: arg.value == null ? null : macro cast ${Context.getTypedExpr(arg.value)}
                                                });

                                        default:
                                    }

                                    final hasRest:Bool = arguments.length > 0 && switch (args[args.length - 1].t)
                                    {
                                        case TAbstract(_.get() => {pack: ['haxe'], name: 'Rest'}, _):
                                            true;

                                        default:
                                            false;
                                    }

                                    final argIds:Array<Expr> = [for (arg in arguments) macro $i{arg.name}];

                                    final callArgs:Array<Expr> = [
                                        for (i => id in argIds)
                                            (hasRest && i == argIds.length - 1) ? {expr: EUnop(OpSpread, false, id), pos: Context.currentPos()}: id
                                    ];

                                    final scriptArgs:Expr = hasRest ? macro ([$a{argIds.slice(0, -1)}] : Array<Dynamic>).concat($e{argIds[argIds.length - 1]}.toArray()) : macro ([$a{argIds}] : Array<Dynamic>);

                                    final retType = makeComplex(ret);

                                    if (shouldContinue)
                                        continue;

                                    fields.push({
                                        pos: Context.currentPos(),
                                        name: name + SUPER_SUFFIX,
                                        kind: FFun({
                                            ret: retType,
                                            args: arguments,
                                            expr: isVoid ? macro {
                                                $p{['super', name]}($a{callArgs});
                                            } : macro {
                                                return $p{['super', name]}($a{callArgs});
                                            }
                                        })
                                    });

                                    final getter:Null<String> = getters[name];
                                    final setter:Null<String> = setters[name];

                                    final valueExpr:Expr = callArgs[0];

                                    fields.push({
                                        pos: Context.currentPos(),
                                        name: name,
                                        access: [AOverride],
                                        kind: FFun({
                                            ret: retType,
                                            args: arguments,
                                            expr: getter != null ? macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                {
                                                    if ($i{ACCESORS}[$v{name}] ?? false)
                                                    {
                                                        return $i{getter};
                                                    } else {
                                                        $i{ACCESORS}[$v{name}] = true;

                                                        final res = $i{INSTANCE}.call($v{name}, ${scriptArgs});

                                                        $i{ACCESORS}[$v{name}] = false;

                                                        return res;
                                                    }
                                                } else {
                                                    return $p{['super', name]}($a{callArgs});
                                                }
                                            } : setter != null ? macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                {
                                                    if ($i{ACCESORS}[$v{name}] ?? false)
                                                    {
                                                        return $i{setter} = $e{valueExpr};
                                                    } else {
                                                        $i{ACCESORS}[$v{name}] = true;

                                                        final res = $i{INSTANCE}.call($v{name}, ${scriptArgs});

                                                        $i{ACCESORS}[$v{name}] = false;

                                                        return res;
                                                    }
                                                } else {
                                                    return $p{['super', name]}($a{callArgs});
                                                }
                                            } : isVoid ? macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                    $i{INSTANCE}.call($v{name}, ${scriptArgs});
                                                else
                                                    $p{['super', name]}($a{callArgs});
                                            } : macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                    return $i{INSTANCE}.call($v{name}, ${scriptArgs});

                                                return $p{['super', name]}($a{callArgs});
                                            }
                                        }),
                                    });

                                default:
                            }
                        }

                    final moduleName:String = type.module.split('.').pop();

                    Context.defineModule(type.pack.concat([type.name + SUFFIX]).join('.'), [{
                        pos: Context.currentPos(),
                        pack: type.pack,
                        name: type.name + SUFFIX,
                        fields: fields,
                        kind: TDClass({
                            pack: type.pack,
                            name: moduleName,
                            sub: moduleName == type.name ? null : type.name,
                            params: [for (par in type.params) TPType(macro : Dynamic)]
                        }, [{
                            pack: ['ale', 'hscript', 'interp'],
                            name: 'IExtensible'
                        }])
                    }], typeImports);

                default:
            }
    }
    #end
}
#end