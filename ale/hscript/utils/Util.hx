package ale.hscript.utils;

import ale.hscript.lexer.TokenType;

import ale.hscript.interp.ScriptedInstance;
import ale.hscript.interp.ScriptedClass;
import ale.hscript.interp.IExtensible;

import ale.hscript.macros.AbstractsMacro;
import ale.hscript.macros.TypeListMacro;
import ale.hscript.macros.EnumsMacro;

import ale.hscript.errors.ErrorType;

import haxe.PosInfos;
import haxe.Log;

@:publicFields
@:allow(ale.hscript.interp.IExtensible)
class Util
{
    static function makeIterator(obj:Dynamic):Iterator<Dynamic>
    {
        #if js
        if (obj is Array)
            return (obj : Array<Dynamic>).iterator();

        if (obj.iterator != null)
            obj = obj.iterator();
        #else
        #if cpp if (obj.iterator != null) #end
            try
            {
                obj = obj.iterator();
            } catch(e:Dynamic) {}
        #end
            
        if (obj.hasNext == null || obj.next == null)
            obj = null;

        return obj;
    }

    static function makeKeyValueIterator(obj:Dynamic):KeyValueIterator<Dynamic, Dynamic>
    {
        #if js
        if (obj is Array)
            return (obj : Array<Dynamic>).keyValueIterator();

        if (obj.keyValueIterator != null)
            obj = obj.keyValueIterator();
        #else
        try
        {
            obj = obj.keyValueIterator();
        } catch(e:Dynamic) {}
        #end

        if (obj.hasNext == null || obj.next == null)
            obj = null;

        return obj;
    }

    static function resolveField(obj:Dynamic, id:String):Dynamic
        return obj is IExtensible ? obj._ALE_HSCRIPT_ResolveField(id) : obj is ScriptedInstance ? obj.get(id) : Reflect.getProperty(obj, id);

    static function assignField(obj:Dynamic, id:String, value:Dynamic):Dynamic
        return if (obj is IExtensible)
        {
            return obj._ALE_HSCRIPT_SetField(id, value);
        } else if (obj is ScriptedInstance) {
            obj.set(id, value);
        } else {
            Reflect.setProperty(obj, id, value);

            value;
        }

    static function createInstance(obj:Dynamic, ?args:Array<Dynamic>, ?imports:Map<String, Dynamic>):Dynamic
        return obj is ScriptedClass ? obj.instance(args, imports) : Type.createInstance(obj, args ?? []);

    static function resolveClass(module:String):Dynamic
    {
        var res:Dynamic = null;
        
        for (mod in [module, module + EnumsMacro.SUFFIX, module + AbstractsMacro.SUFFIX])
            if ((res = Type.resolveClass(mod)) != null)
                break;

        res ??= TypeListMacro.typedefs[module];

        if (res == null)
            throw ETypeNotFound(module);

        return res;
    }

    static function isOfType(obj:Dynamic, type:Dynamic):Bool
        return Std.isOfType(obj, type);


    static function resolveSourceData(script:String, ?name:String):SourceData
    {
        final basePath:String = Config.SCRIPT_PATH + script;

        final path:String = basePath + Config.SCRIPT_EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        final baseName:String = name ?? (isFile ? script : Config.SCRIPT_NAME);

        return {
            source: isFile ? Config.FILE_READER(path) : script,
            name: baseName + Config.SCRIPT_EXTENSION,
        };
    }


    static final stringToTokenType:Map<String, TokenType> = [
        'abstract' => TAbstract,
        'as' => TAs,
        'break' => TBreak,
        'case' => TCase,
        'cast' => TCast,
        'catch' => TCatch,
        'class' => TClass,
        'continue' => TContinue,
        'do' => TDo,
        'dynamic' => TDynamic,
        'else' => TElse,
        'enum' => TEnum,
        'extends' => TExtends,
        'extern' => TExtern,
        'false' => TFalse,
        'final' => TFinal,
        'for' => TFor,
        'function' => TFunction,
        'if' => TIf,
        'implements' => TImplements,
        'import' => TImport,
        'in' => TIn,
        'is' => TIs,
        'inline' => TInline,
        'interface' => TInterface,
        'macro' => TMacro,
        'new' => TNew,
        'null' => TNull,
        'operator' => TOperator,
        'overload' => TOverload,
        'override' => TOverride,
        'package' => TPackage,
        'private' => TPrivate,
        'public' => TPublic,
        'return' => TReturn,
        'static' => TStatic,
        'super' => TSuper,
        'switch' => TSwitch,
        'this' => TThis,
        'throw' => TThrow,
        'true' => TTrue,
        'try' => TTry,
        'typedef' => TTypedef,
        'untyped' => TUntyped,
        'using' => TUsing,
        'var' => TVar,
        'while' => TWhile
    ];


    static function print<T>(val:T, ?pos:PosInfos):T
    {
        Log.trace(val, pos);

        return val;
    }
}