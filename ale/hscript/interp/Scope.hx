package ale.hscript.interp;

class Scope
{
    var parent:Scope;

    public var variables:Map<String, Dynamic>;

    public function new(?parent:Scope)
    {
        this.parent = parent;

        variables = new Map<String, Dynamic>();
    }

    public function define(id:String, value:Dynamic):Dynamic
    {
        variables[id] = value;

        return value;
    }

    public function set(id:String, value:Dynamic):Dynamic
    {
        if (variables.exists(id))
        {
            variables[id] = value;

            return value;
        }
        
        if (parent != null)
            return parent.set(id, value);

        return null;
    }

    public function get(id:String):Dynamic
        return variables[id] ?? parent?.get(id);

    public function exists(id:String):Dynamic
        return variables.exists(id) || parent?.exists(id);
}