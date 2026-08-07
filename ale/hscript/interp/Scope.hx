package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Property;

class Scope
{
    var parent:Scope;

    public var variables:Map<String, Variable>;

    public var superInstance(default, set):Dynamic;
    function set_superInstance(value:Dynamic)
    {
        superFields = null;

        if (value != null)
        {
            final cls:Class<Dynamic> = Type.getClass(value);

            if (cls != null)
                superFields = Type.getInstanceFields(cls);
        }

        return superInstance = value;
    }

    function superExists(id:String):Bool
        return superInstance != null && (Reflect.getProperty(superInstance, id) != null || Reflect.hasField(superInstance, id) || superFields.contains(id));

    var superFields(default, null):Array<Dynamic>;

    public function new(?parent:Scope, ?superInstance:Dynamic, ?context:Dynamic)
    {
        this.parent = parent;

        this.superInstance = superInstance;

        variables = new Map<String, Variable>();
    }

    public function define(id:String, value:Dynamic, ?getter:Property = PDefault, ?setter:Property = PDefault, ?isFinal:Bool = false):Dynamic
    {
        variables[id] = {
            value: value,
            getter: getter,
            setter: setter,
            isFinal: isFinal
        };

        return value;
    }

    public function set(id:String, value:Dynamic):Dynamic
    {
        final scope = resolve(id);

        if (scope == null)
        {
            if (superExists(id))
            {
                Reflect.setProperty(superInstance, id, value);

                return value;
            }

            throw ErrorType.EUnknownVariable(id);
            
            return null;
        }

        final theVar = scope.variables[id];

        if (theVar.isFinal)
        {
            throw ErrorType.EFinalAssign(id);

            return null;
        }

        return switch (theVar.setter)
        {
            case PDefault, PNull:
                theVar.value = value;

            case PSet:
                if (theVar.bypassSetter)
                {
                    theVar.value = value;
                } else {
                    final oldBypass = theVar.bypassSetter;

                    theVar.bypassSetter = true;

                    final res:Dynamic = Reflect.callMethod(null, scope.variables['set_' + id].value, [value]);

                    theVar.bypassSetter = oldBypass;

                    res;
                }

            case PGet, PNever:
                throw ErrorType.ENeverWrite(id);

                null;
        }
    }

    public function get(id:String):Dynamic
    {
        final scope = resolve(id);

        if (scope == null)
        {
            if (superExists(id))
                return Reflect.getProperty(superInstance, id);

            throw ErrorType.EUnknownVariable(id);
            
            return null;
        }

        final theVar = scope.variables[id];

        return switch (theVar.getter)
        {
            case PDefault, PNull:
                theVar.value;

            case PGet:
                if (theVar.bypassGetter)
                {
                    theVar.value;
                } else {
                    final oldBypass = theVar.bypassGetter;

                    theVar.bypassGetter = true;

                    final res:Dynamic = Reflect.callMethod(null, scope.variables['get_' + id].value, []);

                    theVar.bypassGetter = oldBypass;

                    res;
                }

            case PSet, PNever:
                throw ErrorType.ENeverRead(id);

                null;
        }
    }

    public function exists(id:String):Bool
        return resolve(id) != null;

    function resolve(id:String):Scope
        return variables.exists(id) ? this : parent?.resolve(id);

    public function reset(?parent:Scope, ?superInstance:Dynamic)
    {
        this.parent = parent;

        this.superInstance = superInstance;

        variables.clear();
    }
}