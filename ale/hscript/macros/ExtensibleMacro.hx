
package ale.hscript.macros;

import ale.hscript.MacrosConfig;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class ExtensibleMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Extensible';
    public static final SUPER_SUFFIX:String = '_ALE_HScript_super';
    static final INSTANCE:String = '_ALE_HScript_Scripted';
    static final LIST:String = '_ALE_HScript_Fields';
    static final RESOLVE:String = '_ALE_HSCRIPT_ResolveField';
    static final SET:String = '_ALE_HSCRIPT_SetField';
    static final ACCESORS:String = '_ALE_HSCRIPT_AccessorsBypass';

    #if macro
    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (moduleType in types)
            switch (moduleType)
            {
                case TClassDecl(clsRef):
                    final type:ClassType = clsRef.get();

                    if (type.isExtern || type.isAbstract || type.isFinal || type.isInterface || type.isPrivate || type.meta.has(':nativeGen') || type.meta.has(':include') || type.meta.has(':structInit') || type.name.endsWith(AbstractsMacro.SUFFIX) || type.name.endsWith(EnumsMacro.SUFFIX) || type.name.endsWith(SUFFIX))
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
                        if (curClass.params.length > 0 || curClass.isPrivate)
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

                    final constructorArgs:Int = switch (constructor.type)
                    {
                        case TFun(args, _):
                            args.length;

                        default:
                            -1;
                    }

                    var superArgs:Array<Expr> = [for (i in 0...constructorArgs) macro cast localArgs[$v{i}]];

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
                                    return $i{INSTANCE}.get(id);
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
                                    return $i{INSTANCE}.set(id, value);
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
                                    $i{INSTANCE} = instance;

                                    instance.preConstructor(args);

                                    var localArgs = instance.constructorArgs() ?? args;

                                    super($a{superArgs});

                                    instance.nativeInstance = this;
                                    instance._this = this;

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
                                    final name:String = field.name;
                                    final callArgs:Array<Expr> = [for (i in 0...args.length) macro $i{'a' + i}];

                                    final defaults:Array<Null<Expr>> = [for (_ in args) null];

                                    switch (typedExpr.expr)
                                    {
                                        case TFunction(func):
                                            for (i => arg in func.args)
                                                defaults[i] = arg.value == null ? null : macro cast ${Context.getTypedExpr(arg.value)};

                                        default:
                                    }

                                    final isVoid:Bool = switch (Context.follow(ret))
                                    {
                                        case TAbstract(ref, _):
                                            ref.get().name == 'Void';

                                        default:
                                            false;
                                    }

                                    function exists(path:TypePath):Bool
                                    {
                                        final fullPath:String = path.pack.concat([path.name]).join('.') + (path.sub == null ? '' : '.' + path.sub);

                                        try
                                        {
                                            return !Macros.isPrivate(Context.getType(fullPath));
                                        } catch(_:Dynamic) {
                                            return false;
                                        }
                                    }

                                    var shouldContinue:Bool = false;

                                    function makeComplex(t:Type):ComplexType
                                    {
                                        if (t == null)
                                            return null;

                                        final complex:ComplexType = Context.toComplexType(t);

                                        if (complex == null)
                                            return null;

                                        switch (complex)
                                        {
                                            case TPath(path):
                                                if (exists(path))
                                                    return complex;

                                                final nPath:TypePath = {
                                                    pack: fieldsClass.pack,
                                                    name: fieldsClass.module.split('.').pop(),
                                                    sub: path.sub ?? path.name
                                                }

                                                if (exists(nPath))
                                                    return TPath(nPath);

                                                shouldContinue = true;

                                                return null;

                                            default:
                                                return complex;
                                        }
                                    }

                                    final arguments = [
                                        for (i => arg in args)
                                            {
                                                type: makeComplex(arg.t),
                                                name: 'a' + i,
                                                opt: arg.opt && defaults[i] == null,
                                                value: defaults[i]
                                            }
                                    ];

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
                                                if ($i{INSTANCE}.methods.exists($v{name}))
                                                {
                                                    if ($i{ACCESORS}[$v{name}] ?? false)
                                                    {
                                                        return $i{getter};
                                                    } else {
                                                        $i{ACCESORS}[$v{name}] = true;

                                                        final res = $i{INSTANCE}.call($v{name}, [$a{callArgs}]);

                                                        $i{ACCESORS}[$v{name}] = false;

                                                        return res;
                                                    }
                                                } else {
                                                    return $p{['super', name]}($a{callArgs});
                                                }
                                            } : setter != null ? macro {
                                                if ($i{INSTANCE}.methods.exists($v{name}))
                                                {
                                                    if ($i{ACCESORS}[$v{name}] ?? false)
                                                    {
                                                        return $i{setter} = $e{valueExpr};
                                                    } else {
                                                        $i{ACCESORS}[$v{name}] = true;

                                                        final res = $i{INSTANCE}.call($v{name}, [$a{callArgs}]);

                                                        $i{ACCESORS}[$v{name}] = false;

                                                        return res;
                                                    }
                                                } else {
                                                    return $p{['super', name]}($a{callArgs});
                                                }
                                            } : isVoid ? macro {
                                                if ($i{INSTANCE}.methods.exists($v{name}))
                                                    $i{INSTANCE}.call($v{name}, [$a{callArgs}]);
                                                else
                                                    $p{['super', name]}($a{callArgs});
                                            } : macro {
                                                if ($i{INSTANCE}.methods.exists($v{name}))
                                                    return $i{INSTANCE}.call($v{name}, [$a{callArgs}]);

                                                return $p{['super', name]}($a{callArgs});
                                            }
                                        }),
                                    });

                                default:
                            }
                        }

                    final moduleName:String = type.module.split('.').pop();

                    Context.defineType({
                        pos: Context.currentPos(),
                        pack: type.pack,
                        name: type.name + SUFFIX,
                        fields: fields,
                        kind: TDClass({
                            pack: type.pack,
                            name: moduleName,
                            sub: moduleName == type.name ? null : type.name
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