
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
    static final INSTANCE:String = '_ALE_HScript_Scripted';
    static final LIST:String = '_ALE_HScript_Fields';
    static final RESOLVE:String = '_ALE_HSCRIPT_ResolveField';
    static final SET:String = '_ALE_HSCRIPT_SetField';
    static final ACCESORS:String = '_ALE_HSCRIPT_AccessorsBypass';
    static final ARGUMENT:String = '_ALE_HSCRIPT_ARGUMENT';

    #if macro
    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (moduleType in types)
            switch (moduleType)
            {
                case TClassDecl(clsRef):
                    final type:ClassType = clsRef.get();

                    if (type.params.length > 0 || (type.params.length > 0 && (type.meta.has(':hxGen') || type.meta.has(':genericBuild') || type.meta.has(':generic'))) || type.isExtern || type.isAbstract || type.isFinal || type.isInterface || type.isPrivate || type.meta.has(':nativeGen') || type.meta.has(':include') || type.meta.has(':structInit') || type.name.endsWith(AbstractsMacro.SUFFIX) || type.name.endsWith(EnumsMacro.SUFFIX) || type.name.endsWith(SUFFIX))
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

                    while (curClass != null)
                    {
                        if (curClass.isPrivate)
                        {
                            shouldContinue = true;

                            break;
                        }

                        classes.push(curClass);
                        
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

                    final paramsMap:Map<String, Null<Type>> = [];

                    for (par in type.params)
                        if (par.defaultType != null)
                            paramsMap[par.name] = par.defaultType;
                        else switch (par.t)
                        {
                            case TInst(ref, _):
                                switch (ref.get().kind)
                                {
                                    case KTypeParameter(cons):
                                        paramsMap[par.name] = cons.length > 0 ? cons[0] : TDynamic(null);

                                    default:
                                }

                            default:
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
                            if (field.params.length > 0 || field.isFinal || field.meta.has(':inline') || fieldsList.contains(field.name))
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
                                    var shouldContinue:Bool = Macros.isPrivate(ret);

                                    if (!shouldContinue)
                                        for (arg in args)
                                            if (Macros.isPrivate(arg.t))
                                            {
                                                shouldContinue = true;

                                                break;
                                            }

                                    if (shouldContinue)
                                        continue;

                                    final name:String = field.name;

                                    final arguments:Array<FunctionArg> = [];

                                    function dynamizer(t:Type):Type
                                    {
                                        if (t == null)
                                            return null;

                                        return switch (t)
                                        {
                                            case TInst(_.get() => c, _) if (c.kind.match(KTypeParameter(_))):
                                                paramsMap[c.name] ?? TDynamic(null);

                                            default:
                                                TypeTools.map(t, dynamizer);
                                        }
                                    }

                                    switch (typedExpr.expr)
                                    {
                                        case TFunction(func):
                                            for (i => arg in func.args)
                                                arguments.push({
                                                    name: arg.v.name + ARGUMENT,
                                                    type: Context.toComplexType(dynamizer(arg.v.t)),
                                                    opt: args[i].opt && arg.value == null,
                                                    meta: arg.v.meta.get(),
                                                    value: arg.value == null ? null : macro cast ${Context.getTypedExpr(arg.value)}
                                                });

                                        case TConst(_):
                                            continue;

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

                                    final isVoid:Bool = switch (Context.follow(ret))
                                    {
                                        case TAbstract(ref, _):
                                            ref.get().name == 'Void';

                                        default:
                                            false;
                                    }

                                    final retType = Context.toComplexType(dynamizer(ret));

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

                                                        final res = $i{INSTANCE}.call($v{name}, [${scriptArgs}]);

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

                                                        final res = $i{INSTANCE}.call($v{name}, [${scriptArgs}]);

                                                        $i{ACCESORS}[$v{name}] = false;

                                                        return res;
                                                    }
                                                } else {
                                                    return $p{['super', name]}($a{callArgs});
                                                }
                                            } : isVoid ? macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                    $i{INSTANCE}.call($v{name}, [${scriptArgs}]);
                                                else
                                                    $p{['super', name]}($a{callArgs});
                                            } : macro {
                                                if ($i{INSTANCE}?.methods.exists($v{name}) ?? false)
                                                    return $i{INSTANCE}.call($v{name}, [${scriptArgs}]);

                                                return $p{['super', name]}($a{callArgs});
                                            }
                                        }),
                                    });

                                default:
                            }
                        }

                    var fixed:Bool = type.name != 'Camera';

                    if (!fixed)
                        for (field in fields)
                            if (field?.name == 'drawPixels')
                            {
                                fixed = true;

                                break;
                            }

                    if (!fixed)
                        throw 'drawPixels does\'nt exists';

                    final moduleName:String = type.module.split('.').pop();

                    Context.defineType({
                        pos: Context.currentPos(),
                        pack: type.pack,
                        name: type.name + SUFFIX,
                        fields: fields,
                        kind: TDClass({
                            pack: type.pack,
                            name: moduleName,
                            sub: moduleName == type.name ? null : type.name,
                            params: [for (par in type.params) par.defaultType == null ? TPType(macro : Dynamic) : TPType(Context.toComplexType(par.defaultType))]
                        }, [{
                            pack: ['ale', 'hscript', 'interp'],
                            name: 'IExtensible'
                        }])
                    });

                default:
            }
    }
    #end
}
#end