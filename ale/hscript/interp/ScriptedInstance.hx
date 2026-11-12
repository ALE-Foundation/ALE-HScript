package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ScriptedInstance extends Interp
{
    var type:ScriptedClass;
    var superType:Extensible;

    function toString()
        return methods.exists('toString') ? call('toString') : type.toString();

    public var methods:Map<String, Scope> = [];

    var _this(default, set):Dynamic;
    function set__this(val:Dynamic):Dynamic
    {
        if (superType is ScriptedClass)
            (superInstance : ScriptedInstance)._this = val;

        return _this = val;
    }

    var _constructor:Constructor;

    public function new(type:ScriptedClass, body:Array<Expr>, ?superType:Extensible, ?imports:Map<String, Dynamic>)
    {
        this.type = type;
        this.superType = superType;

        super();

        name = type.toString();

        if (superType != null && superType is ScriptedClass)
        {
            superInstance = (superType : ScriptedClass).instance();

            final sup:ScriptedInstance = cast superInstance;

            scope = variables = new Scope(sup.variables);

            methods = sup.methods;
        }

        _this = this;

        if (imports != null)
            this.imports = imports;

        executeBody(body);
    }

    public function initPreConstructor(args:Array<Dynamic>)
    {
        enterScope(variables);

        for (i => arg in _constructor.funcArgs)
            scope.define(arg.id, args[i] ?? eval(arg.value));

        eval(_constructor.pre);
    }

    public function getConstructorArgs():Array<Dynamic>
        return evalArray(_constructor.superArgs);

    public function initPostConstructor()
    {
        eval(_constructor.post);

        exitScope();
    }

    public function callConstructor(?args:Array<Dynamic>):Dynamic
    {
        if (args != null)
            if (_constructor == null)
            {
                Reflect.callMethod(null, get('new'), args);
            } else {
                if (superType is ScriptedClass)
                {
                    var removeScope:Bool = false;
                    
                    try
                    {
                        initPreConstructor(args);

                        removeScope = true;

                        (superInstance : ScriptedInstance).callConstructor(getConstructorArgs());

                        initPostConstructor();
                    } catch(e:Dynamic) {
                        if (removeScope)
                            exitScope();

                        throw e;
                    }
                } else {
                    return Type.createInstance((superType : Class<IExtensible>), [this, args]);
                }
            }

        return this;
    }

    public function executeBody(body:Array<Expr>)
        errorHandled(() -> {
            for (expr in body)
                switch ((lastExpr = expr)?.type)
                {
                    case EExtendedConstructor(pre, superArgs, post, funcArgs):
                        _constructor = new Constructor(pre, superArgs, post, funcArgs);

                        null;

                    case EVarDecl(id, _, _, _, _, _):
                        if (variables.exists(id))
                            throw EDuplicated(id);
                        else
                            eval(expr);

                    case EFunctionDecl(id, access, value, overr):
                        if (methods.exists(id) && !overr)
                        {
                            throw EDuplicated(id);
                        } else {
                            final func:Dynamic = eval(value);

                            define(id, func, access, PDefault, PNever, true);

                            if (id != 'new')
                                methods[id] = scope;
                        }

                    case null:

                    default:
                        throw EInvalidExpression(expr.type);
                }
        });

    override function eval(expr:Expr):Dynamic
        return switch ((lastExpr = expr)?.type)
        {
            case EThis:
                _this;

            default:
                super.eval(expr);
        }

    override function defaultResolve(id:String):Dynamic
    {
        if (scope.exists(id, variables))
            return scope.get(id, methods['get_' + id], variables);

        if (methods.exists(id))
            return methods[id].variables[id].value;

        return get(id);
    }

    override function defaultAssign(id:String, value:Dynamic):Dynamic
    {
        if (scope.exists(id, variables))
            return scope.set(id, value);

        if (methods.exists(id))
            return methods[id].variables[id].value = value;

        return set(id, value);
    }
    
    public function call(id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, methods[id].get(id), args ?? []);

    public function get(id:String):Dynamic
        return variables.get(id, methods['get_' + id]);

    public function set(id:String, value:Dynamic):Dynamic
        return variables.set(id, value, methods['set_' + id]);
}