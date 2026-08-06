package ale.hscript.interp;

import ale.hscript.parser.Property;

class Scope
{
    var parent:Scope;

    public var variables:Map<String, Variable>;

    var bypassGetter:Map<String, Bool>;
    var bypassSetter:Map<String, Bool>;

    public function new(?parent:Scope)
    {
        this.parent = parent;

        variables = new Map<String, Variable>();

        bypassGetter = new Map<String, Bool>();
        bypassSetter = new Map<String, Bool>();
    }

    public function define(id:String, value:Dynamic, ?getter:Property = PDefault, ?setter:Property = PDefault, ?isFinal:Bool = false)
        variables[id] = {
            value: value,
            getter: getter,
            setter: setter,
            isFinal: isFinal
        };

    public function set(id:String, value:Dynamic):Dynamic
    {
        final scope = resolve(id);

        if (scope == null)
            return null;

        final theVar = scope.variables[id];

        if (theVar.isFinal)
        {
            throw 'Cannot assign final "$id"';

            return null;
        }

        return switch (theVar.setter)
        {
            case PDefault, PNull:
                theVar.value = value;

            case PSet:
                if (scope.bypassSetter[id])
                {
                    theVar.value = value;
                } else {
                    final oldBypass = scope.bypassSetter[id];

                    scope.bypassSetter[id] = true;

                    final res:Dynamic = Reflect.callMethod(null, scope.variables['set_' + id].value, [value]);

                    scope.bypassSetter[id] = oldBypass;

                    res;
                }

            case PGet, PNever:
                throw 'Expression "$id" cannot be accessed for writing';

                null;
        }
    }

    public function get(id:String):Dynamic
    {
        final scope = resolve(id);

        if (scope == null)
            return null;

        final theVar = scope.variables[id];

        return switch (theVar.getter)
        {
            case PDefault, PNull:
                theVar.value;

            case PGet:
                if (scope.bypassGetter[id])
                {
                    theVar.value;
                } else {
                    final oldBypass = scope.bypassGetter[id];

                    scope.bypassGetter[id] = true;

                    final res:Dynamic = Reflect.callMethod(null, scope.variables['get_' + id].value, []);

                    scope.bypassGetter[id] = oldBypass;

                    res;
                }

            case PSet, PNever:
                throw 'The expression "$id" cannot be accessed for reading';

                null;
        }
    }

    public function exists(id:String):Dynamic
        return resolve(id) != null;

    function resolve(id:String):Scope
        return variables.exists(id) ? this : parent?.resolve(id);
}