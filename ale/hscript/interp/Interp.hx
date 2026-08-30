package ale.hscript.interp;

import ale.hscript.interp.Scope;

import ale.hscript.parser.Expr;

import ale.hscript.macros.AbstractsMacro;
import ale.hscript.macros.TypeListMacro;
import ale.hscript.macros.EnumsMacro;

import ale.hscript.errors.ErrorType;

abstract class Interp
{
    public var name:String;

    public var imports:Map<String, Class<Dynamic>>;

    public var variables:Scope;

    public var scope:Scope;

    public var superInstance(default, set):Dynamic;
    function set_superInstance(value:Dynamic)
    {
        superFields = null;

        if (value != null)
        {
            final cls:Class<Dynamic> = Type.getClass(value);

            if (cls != null)
                superFields = Type.getInstanceFields(cls);
        }

        return superInstance = value;
    }

    var superFields(default, null):Array<Dynamic>;

    function superExists(id:String):Bool
        return superInstance != null && (Reflect.getProperty(superInstance, id) != null || Reflect.hasField(superInstance, id) || superFields.contains(id));

    public var softPackage:String;

    var usings:Array<Dynamic> = [];

    public function new(?name:String, ?superInstance:Dynamic)
    {
        this.name = name;

        imports = new Map<String, Class<Dynamic>>();

        variables = scope = new Scope(null);

        this.superInstance = superInstance;

        for (cls in Config.IMPORTS)
            imports[Type.getClassName(cls).split('.').pop()] = cls;
        
        for (cls in Config.ABSTRACTS)
            imports[cls.split('.').pop()] = resolveType(cls);

        for (key => val in Config.TYPEDEFS)
            imports[key] = val;

        for (key => val in Config.VARIABLES)
            variables.define(key, val);

        init();
    }

    function init() {}
    

    abstract public function execute(exprs:Array<Expr>):Dynamic;


    function resolveType(mod:String, ?allowPackage:Bool = true):Class<Dynamic>
    {
        for (module in [mod, softPackage == null || !allowPackage ? null : softPackage + '.' + mod, mod + EnumsMacro.SUFFIX, mod + AbstractsMacro.SUFFIX])
            if (module != null)
                for (method in [
                    () -> imports[module],
                    () -> Type.resolveClass(module)
                ])
                {
                    final res:Class<Dynamic> = method();

                    if (res != null)
                        return res;
                }

        throw ErrorType.ETypeNotFound(mod);

        return null;
    }


    function makeIterator(obj:Dynamic):Iterator<Dynamic>
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

    function makeKeyValueIterator(obj:Dynamic):KeyValueIterator<Dynamic, Dynamic>
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


    function createScope(parent:Scope):Scope
        return new Scope(parent);
}