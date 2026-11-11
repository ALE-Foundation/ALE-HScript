package ale.hscript.interp;

class ScriptedInstance
{
    final type:ScriptedClass;

    public function toString():String
        return type.toString();

    public final variables:Scope;

    public function new(type:ScriptedClass, variables:Scope)
    {
        this.type = type;
        this.variables = variables;
    }

    public function get(id:String):Dynamic
        return variables.get(id, variables);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value, variables);

    // TODO
    public function is(type:Dynamic)
        return Std.string(type) == this.type.id;
}