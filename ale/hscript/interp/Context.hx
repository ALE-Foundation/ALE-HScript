package ale.hscript.interp;

class Context
{
    public var publicVariables:Scope;
    public var staticVariables:Scope;

    public function new()
    {
        publicVariables = new Scope(null);
        staticVariables = new Scope(null);
    }
}