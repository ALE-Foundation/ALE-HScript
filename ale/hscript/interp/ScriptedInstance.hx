package ale.hscript.interp;

class ScriptedInstance
{
    public final scripted:ScriptedClass;
    public final scope:Scope;

    public var scriptedSuper:ScriptedInstance;

    public function new(scripted:ScriptedClass, scope:Scope)
    {
        this.scripted = scripted;
        this.scope = scope;
    }

    public inline function get(id:String):Dynamic
        return scope.get(id);

    public inline function set(id:String, value:Dynamic):Dynamic
        return scope.set(id, value);
}