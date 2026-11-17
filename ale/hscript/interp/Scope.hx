package ale.hscript.interp;

import ale.hscript.parser.Property;

import ale.hscript.errors.ErrorType;

class Scope
{
    public var parent:Null<Scope>;

    public var variables:Map<String, Variable>;

    public function new(?parent:Scope)
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

    public function resolve(id:String, ?scp:Scope, ?until:Scope):Scope
    {
        var scope:Scope = scp ?? this;

        while (scope != null && scope != until)
            if (scope.variables.exists(id))
                break;
            else
                scope = scope.parent;

        if (scope == null || scope == until)
            return null;

        return scope;
    }

    public static function call(scope:Scope, id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, scope.variables[id].value, args ?? []);

    public static function read(scp:Scope, id:String, ?accScp:Scope):Dynamic
    {
        final data:Variable = scp.variables[id];
        
        return switch (data.getter)
        {
            case PDefault, PNull, null:
                data.value;

            case PGet:
                if (data.bypassGetter)
                {
                    data.value;
                } else {
                    final oldBypass:Bool = data.bypassGetter;

                    data.bypassGetter = true;

                    final res:Dynamic = call(accScp ?? scp, 'get_' + id);

                    data.bypassGetter = oldBypass;

                    res;
                }

            case PNever, PSet:
                throw ENeverRead(id);

            default:
                null;
        }
    }

    public static function write(scp:Scope, id:String, value:Dynamic, ?accScp:Scope):Dynamic
    {
        final data:Variable = scp.variables[id];

        if (data.isFinal && data.value != null)
            throw EFinalAssign(id);

        return switch (data.setter)
        {
            case PDefault, PNull, null:
                data.value = value;

            case PSet:
                if (data.bypassSetter)
                {
                    data.value = value;
                } else {
                    final oldBypass:Bool = data.bypassSetter;

                    data.bypassSetter = true;

                    final res:Dynamic = call(accScp ?? scp, 'set_' + id, [value]);

                    data.bypassSetter = oldBypass;

                    res;
                }

            case PNever, PGet:
                throw ENeverWrite(id);

            default:
                null;
        }
    }
}