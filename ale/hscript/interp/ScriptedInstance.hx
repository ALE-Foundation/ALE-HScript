package ale.hscript.interp;

class ScriptedInstance<T>
{
    public final scripted:ScriptedClass<T>;
    public final scope:Scope<T>;

    public var scriptedSuper:ScriptedInstance<T>;

    public function new(scripted:ScriptedClass<T>, scope:Scope<T>)
    {
        this.scripted = scripted;
        this.scope = scope;
    }

    public inline function get(id:String):Dynamic
        return scope.get(id);

    public inline function set(id:String, value:Dynamic):Dynamic
        return scope.set(id, value);
}