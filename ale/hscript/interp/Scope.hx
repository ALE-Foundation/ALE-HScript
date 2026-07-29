package ale.hscript.interp;

class Scope
{
    public var parent:Scope;

    public var variables:Map<String, Dynamic> = [];

    public function new(?parent:Scope)
        this.parent = parent;

    public function exists(id:String):Bool
        return variables.exists(id) || parent?.exists(id) == true;

    public function set(id:String, value:Dynamic):Dynamic
    {
        if (variables.exists(id))
            variables.set(id, value);
        else if (parent?.exists(id))
            parent.set(id, value);

        return value;
    }

    public function get(id:String):Dynamic
    {
        if (variables.exists(id))
            return variables.get(id);

        if (parent?.exists(id))
            return parent.get(id);

        return null;
    }

    public function define(id:String, ?value:Dynamic):Dynamic
    {
        variables.set(id, value);

        return value;
    }
}