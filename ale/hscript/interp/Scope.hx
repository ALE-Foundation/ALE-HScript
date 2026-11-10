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
        final scope:Scope = resolve(id);

        final data:Variable = scope.variables[id];

        return switch (data.getter)
        {
            case PDefault, null:
                data.value;

            case PGet:
                if (data.bypassGetter)
                {
                    data.value;
                } else {
                    final oldBypass:Bool = data.bypassGetter;

                    data.bypassGetter = true;

                    final res:Dynamic = call(scope, 'get_' + id);

                    data.bypassGetter = oldBypass;

                    res;
                }

            case PNever, PSet:
                throw ENeverRead(id);

            default:
                null;
        }
    }

    public function call(scope:Scope, id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, scope.variables[id].value, args ?? []);

    public function set(id:String, value:Dynamic):Dynamic
    {
        final scope:Scope = resolve(id);

        final data:Variable = scope.variables[id];

        if (data.isFinal)
            throw EFinalAssign(id);

        return switch (data.setter)
        {
            case PDefault, null:
                data.value = value;

            case PSet:
                if (data.bypassSetter)
                {
                    data.value = value;
                } else {
                    final oldBypass:Bool = data.bypassSetter;

                    data.bypassSetter = true;

                    final res:Dynamic = call(scope, 'set_' + id, [value]);

                    data.bypassSetter = oldBypass;

                    res;
                }

            case PNever, PGet:
                throw ENeverWrite(id);

            default:
                null;
        }
    }

    public function exists(id:String):Bool
        return try
        {
            resolve(id);

            true;
        } catch(_) {
            false;
        }

    function resolve(id:String):Scope
    {
        var scope:Scope = this;

        while (scope != null)
            if (scope.variables.exists(id))
                break;
            else
                scope = scope.parent;

        if (scope == null)
            throw EUnknownVariable(id);

        return scope;
    }
}