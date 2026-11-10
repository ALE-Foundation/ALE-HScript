package ale.hscript.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class EnumsMacro
{
    public static final SUFFIX:String = '_ALE_HScript_Enum';

    #if macro
    public static function onAfterTyping(types:Array<ModuleType>)
        for (type in types)
            switch (type)
            {
                case TEnumDecl(ref):
                    final enumDecl:EnumType = ref.get();

                    if (enumDecl.params.length > 0 || enumDecl.isPrivate || enumDecl.isExtern)
                        continue;

                    final pos:Position = Context.currentPos();

                    final path:Array<String> = enumDecl.module.split('.').concat([enumDecl.name]);

                    final enumType:ComplexType = Context.toComplexType(TEnum(ref, []));

                    final fields:Array<Field> = [];

                    for (val in enumDecl.constructs)
                    {
                        if (val.params.length > 0)
                            continue;

                        final ctorPath:Array<String> = path.concat([val.name]);

                        switch (val.type)
                        {
                            case TFun(args, _):
                                final fnArgs:Array<FunctionArg> = [];
                                final callArgs:Array<Expr> = [];

                                for (arg in args)
                                {
                                    fnArgs.push({
                                        name: arg.name,
                                        type: Context.toComplexType(arg.t),
                                        opt: arg.opt
                                    });

                                    callArgs.push({
                                        expr: EConst(CIdent(arg.name)),
                                        pos: pos
                                    });
                                }

                                fields.push({
                                    name: val.name,
                                    access: [APublic, AStatic],
                                    kind: FFun({
                                        args: fnArgs,
                                        ret: enumType,
                                        expr: macro return $p{ctorPath}($a{callArgs})
                                    }),
                                    pos: val.pos
                                });

                            default:
                                fields.push({
                                    name: val.name,
                                    access: [APublic, AStatic, AFinal],
                                    kind: FProp('default', 'never', enumType, macro $p{ctorPath}),
                                    pos: val.pos
                                });

                                fields.push({
                                    name: 'get_' + val.name,
                                    access: [AStatic],
                                    kind: FFun({
                                        ret: enumType,
                                        expr: macro return $p{ctorPath},
                                        args: []
                                    }),
                                    pos: val.pos
                                });
                        }
                    }

                    Context.defineType({
                        pack: enumDecl.pack,
                        name: enumDecl.name + SUFFIX,
                        kind: TDClass(null, [], false, true, false),
                        fields: fields,
                        pos: pos
                    });

                default:
            }
    #end
}