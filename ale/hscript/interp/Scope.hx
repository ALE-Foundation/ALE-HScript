package ale.hscript.interp;

import ale.hscript.parser.Property;

import ale.hscript.errors.ErrorType;

class Scope
{
    public var parent:Null<Scope>;

    public var variables:Map<String, Variable>;

    public function new(parent:Null<Scope>)
    {
        this.parent = parent;

        variables = new Map();
    }

    public function define(id:String, ?value:Dynamic, ?getter:Property, ?setter:Property, ?isFinal:Bool)
        variables[id] = {
            value: value,
            getter: getter,
            setter: setter,
            isFinal: isFinal
        }

    public function get(id:String):Dynamic
    {
        final data:Variable = resolve(id);

        return switch (data.getter)
        {
            case PDefault, null:
                data.value;

            case PGet:
                call('get_' + id);

            case PNever, PSet:
                throw ENeverRead(id);

            default:
                null;
        }
    }

    public function call(id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, get(id), args ?? []);

    // TODO: Setters
    public function set(id:String, value:Dynamic):Dynamic
    {
        final data:Variable = resolve(id);

        if (data.isFinal)
            throw EFinalAssign(id);

        return switch (data.setter)
        {
            case PDefault, null:
                data.value = value;

            case PSet:
                call('set_' + id, [value]);

            case PNever, PGet:
                throw ENeverWrite(id);

            default:
                null;
        }
    }

    function resolve(id:String):Dynamic
    {
        var result:Dynamic = null;

        var scope:Scope = this;

        while (scope != null)
        {
            result = scope.variables[id];

            if (result == null)
                scope = scope.parent;
            else
                break;
        }

        if (scope == null)
            throw EUnknownVariable(id);

        return result;
    }

    
}