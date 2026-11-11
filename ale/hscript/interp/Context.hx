package ale.hscript.interp;

class Context
{
    public var variables:Scope;

    public function new()
        variables = new Scope(null);
}