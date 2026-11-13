
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
    public static final INSTANCE:String = '_ALE_HScript_Scripted';
    public static final LIST:String = '_ALE_HScript_Fields';

    #if macro
    public static function onAfterTyping(types:Array<ModuleType>)
    {
        for (moduleType in types)
            switch (moduleType)
            {
                case TClassDecl(clsRef):
                    final type:ClassType = clsRef.get();

                    if (type.isExtern || type.isAbstract || type.isFinal || type.isInterface || type.isPrivate || type.name.endsWith(AbstractsMacro.SUFFIX) || type.name.endsWith(EnumsMacro.SUFFIX) || type.name.endsWith(SUFFIX) || type.params.length > 0)
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

                    var constructor:ClassField = null;
                    var constructorClass:ClassType = type;

                    while (constructor == null && constructorClass != null)
                    {
                        constructor = constructorClass.constructor?.get();
                        constructorClass = constructorClass.superClass?.t?.get();
                    }

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

                    final fields:Array<Field> = [
                        {
                            pos: Context.currentPos(),
                            name: LIST,
                            access: [AFinal],
                            kind: FVar(macro : Array<String>)
                        },
                        {
                            pos: Context.currentPos(),
                            name: INSTANCE,
                            access: [AFinal],
                            kind: FVar(macro : ale.hscript.interp.ScriptedInstance)
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
                                    instance.superInstance = this;
                                    instance._this = this;

                                    $i{LIST} = std.Type.getInstanceFields(std.Type.getSuperClass(std.Type.getClass(this)));

                                    $i{INSTANCE} = instance;

                                    instance.preConstructor();

                                    var localArgs = instance.constructorArgs() ?? args;

                                    super($a{superArgs});

                                    instance.postConstructor();
                                }
                            })
                        }
                    ];

                    final fieldsList:Array<String> = ['new'];

                    var fieldsClass:ClassType = type;

                    while (fieldsClass != null)
                    {
                        for (field in fieldsClass.fields.get())
                        {
                            if (field.params.length > 0 || field.isFinal || fieldsList.contains(field.name))
                                continue;

                            fieldsList.push(field.name);

                            switch (field.kind)
                            {
                                case FMethod(MethNormal | MethDynamic):

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
                                                defaults[i] = arg.value == null ? null : Context.getTypedExpr(arg.value);

                                        default:
                                    }

                                    final isVoid:Bool = switch (Context.follow(ret))
                                    {
                                        case TAbstract(ref, _):
                                            ref.get().name == 'Void';

                                        default:
                                            false;
                                    }

                                    final arguments = [
                                        for (i => arg in args)
                                            {
                                                type: Context.toComplexType(arg.t),
                                                name: 'a' + i,
                                                opt: arg.opt && defaults[i] == null,
                                                value: defaults[i]
                                            }
                                    ];

                                    fields.push({
                                        pos: Context.currentPos(),
                                        name: name + SUPER_SUFFIX,
                                        kind: FFun({
                                            ret: Context.toComplexType(ret),
                                            args: arguments,
                                            expr: isVoid ? macro {
                                                $p{['super', name]}($a{callArgs});
                                            } : macro {
                                                return $p{['super', name]}($a{callArgs});
                                            }
                                        })
                                    });

                                    fields.push({
                                        pos: Context.currentPos(),
                                        name: name,
                                        access: [AOverride],
                                        kind: FFun({
                                            ret: Context.toComplexType(ret),
                                            args: arguments,
                                            expr: isVoid ? macro {
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

                        fieldsClass = fieldsClass.superClass?.t?.get();
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
