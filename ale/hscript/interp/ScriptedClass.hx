package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

import ale.hscript.macros.NativeExtensible;
import ale.hscript.macros.ExtensibleMacro;

class ScriptedClass<T>
{
    public final id:String;
    public final body:Array<T>;
    public final parent:ScriptedClass<T>;
    public final nativeParent:Class<NativeExtensible>;
    public final implem:Array<ScriptedInterface>;

    public function new(id:String, body:Array<T>, ?parent:Dynamic, ?implem:Array<ScriptedInterface>)
    {
        function resolveNative():Class<NativeExtensible>
        {
            if (parent == null || parent is ScriptedClass)
                return null;

            final name = Type.getClassName(parent);

            final type = Type.resolveClass(name + ExtensibleMacro.SUFFIX);

            if (type == null)
                throw ECannotExtend(name);

            final inst = Type.createEmptyInstance(type);

            if (inst is NativeExtensible)
                return cast type;
            else
                throw ECannotExtend(name);

            return null;
        }

        this.id = id;
        this.body = body;
        this.parent = parent is ScriptedClass ? parent : null;
        this.nativeParent = resolveNative();
        this.implem = implem;
    }

    public function instance(args:Array<Dynamic>, interp:Interp<T>):ScriptedInstance<T>
    {
        final parent:ScriptedClass<T> = parent;

        final superInst = parent?.instance(null, interp);

        final newScope = interp.createScope(superInst?.scope);

        final inst = new ScriptedInstance<T>(this, newScope);

        newScope.scriptedThis = inst;
        newScope.scriptedSuper = superInst;

        final oldScope = interp.scope;

        interp.scope = newScope;

        try
        {
            if (nativeParent != null)
                newScope.define('new', Reflect.makeVarArgs(args -> {
                    newScope.scriptedSuper = Type.createInstance(nativeParent, [inst, args]);
                }));

            for (expr in body)
                interp.eval(expr);

            for (imp in implem)
                for (field in imp.instance())
                    if (!newScope.exists(field))
                        throw ENeededField(field, imp.id);

            if (args != null)
                Reflect.callMethod(inst, newScope.get('new'), args);
        } catch(e) {
            interp.scope = oldScope;

            throw e;
        }
        
        interp.scope = oldScope;

        return inst;
    }
}