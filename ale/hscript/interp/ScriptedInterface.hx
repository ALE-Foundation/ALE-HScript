package ale.hscript.interp;

class ScriptedInterface
{
    public final id:String;
    public final fields:Array<String>;
    public final parents:Array<ScriptedInterface>;

    public function new(id:String, fields:Array<String>, ?parents:Array<ScriptedInterface>)
    {
        this.id = id;
        this.fields = fields;
        this.parents = parents;
    }

    public function instance():Array<String>
    {
        var result = fields.copy();

        for (par in parents)
            for (field in par.instance())
                if (!result.contains(field))
                    result.push(field);

        return result;
    }
}