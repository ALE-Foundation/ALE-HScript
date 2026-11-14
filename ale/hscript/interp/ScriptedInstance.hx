package ale.hscript.interp;

import ale.hscript.macros.ExtensibleMacro;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

import ale.hscript.utils.Util;

class ScriptedInstance extends Interp
{
    var type:ScriptedClass;
    var superType:Extensible;

    var allowMethodToString:Bool = true;
    
    public function toString()
        return (allowMethodToString && methods.exists('toString')) ? call('toString') : type.toString();

    public var methods:Map<String, Scope> = [];

    public var _this(default, set):Dynamic;
    function set__this(val:Dynamic):Dynamic
    {
        if (superType is ScriptedClass)
            (superInstance : ScriptedInstance)._this = val;

        return _this = val;
    }

    var _constructor:Constructor;
    public var nativeInstance:IExtensible;
        
    public function new(type:ScriptedClass, body:Array<Expr>, ?superType:Extensible, ?imports:Map<String, Dynamic>)
    {
        if (superType != null && !(superType is ScriptedClass) && !(Type.createEmptyInstance(superType) is IExtensible))
        {
            final saved = superType;
            
            superType = cast Type.resolveClass(Type.getClassName(superType) + ExtensibleMacro.SUFFIX);

            if (superType == null)
                throw ECannotExtend(Type.getClassName(saved));
        }

        this.type = type;
        this.superType = superType;

        super();

        name = type.toString();

        if (superType is ScriptedClass)
        {
            superInstance = (superType : ScriptedClass).instance(null, imports);
         
            scope = variables = new Scope(superInstance.variables);
            methods = superInstance.methods;
        }

        _this = this;

        if (imports != null)
            this.imports = imports;

        executeBody(body);

        if (!methods.exists('toString'))
        {
            define('toString', () -> {
                _this.allowMethodToString = false;

                final res:String = _this.toString();

                _this.allowMethodToString = true;

                return res;
            }, [], PDefault, PNever, true);

            methods['toString'] = variables;
        }
    }

    public function preConstructor(?args:Array<Dynamic>)
    {
        if (_constructor == null)
            return;

        enterScope(variables);

        for (i => arg in _constructor.funcArgs)
            scope.define(arg.id, args[i] ?? eval(arg.value));

        eval(_constructor.pre);
    }

    public function constructorArgs():Array<Dynamic>
        return _constructor == null ? null : evalArray(_constructor.superArgs);

    public function postConstructor()
    {
        if (_constructor == null)
            return;

        eval(_constructor.post);

        exitScope();
    }

    public function callConstructor(?args:Array<Dynamic>):Dynamic
    {
        if (args != null)
        {
            _this = this;

            if (_constructor == null)
            {
                if (superType == null)
                {
                    Reflect.callMethod(null, variables.get('new'), args);
                } else {
                    if (superType is ScriptedClass)
                    {
                        superInstance.callConstructor(args);

                        if (superInstance.nativeInstance != null)
                        {
                            _this = nativeInstance = superInstance.nativeInstance;

                            _this._ALE_HScript_Scripted = this;
                        }
                    } else {
                        Type.createInstance(superType, [this, args]);
                    }
                }
            } else {
                if (superType is ScriptedClass)
                {
                    preConstructor(args);

                    superInstance.callConstructor(constructorArgs());

                    if (superInstance.nativeInstance != null)
                    {
                        _this = nativeInstance = superInstance.nativeInstance;

                        _this._ALE_HScript_Scripted = this;
                    }
                    
                    postConstructor();
                } else {
                    Type.createInstance(superType, [this, args]);
                }
            }
        }

        return _this;
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

            case ESuperFieldCall(id, args):
                final resArgs:Array<Dynamic> = evalArray(args);

                try
                {
                    Reflect.callMethod(null, Util.resolveField(superInstance, superInstance is IExtensible ? id + ExtensibleMacro.SUPER_SUFFIX : id), resArgs);
                } catch(e:Dynamic) {
                    if (nativeInstance != null && nativeInstance._ALE_HScript_Fields.exists(id + ExtensibleMacro.SUPER_SUFFIX))
                        Reflect.callMethod(null, Reflect.getProperty(nativeInstance, id + ExtensibleMacro.SUPER_SUFFIX), resArgs);
                    else
                        throw e;
                }

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
            return scope.set(id, value, methods['get_' + id], variables);

        if (methods.exists(id))
            return methods[id].variables[id].value = value;

        return set(id, value);
    }
    
    public function call(id:String, ?args:Array<Dynamic>):Dynamic
        return Reflect.callMethod(null, methods[id].get(id), args ?? []);

    public function get(id:String, ?allowNative:Bool = true):Dynamic
        return try
        {
            variables.get(id, methods['get_' + id]);
        } catch(e:Dynamic) {
            if (allowNative && nativeInstance != null && nativeInstance._ALE_HScript_Fields.exists(id))
                Reflect.getProperty(nativeInstance, id);
            else
                throw e;
        }

    public function set(id:String, value:Dynamic, ?allowNative:Bool = true):Dynamic
    {
        return try
        {
            variables.set(id, value, methods['set_' + id]);
        } catch(e:Dynamic) {
            if (allowNative && nativeInstance != null && nativeInstance._ALE_HScript_Fields.exists(id))
            {
                Reflect.setProperty(nativeInstance, id, value);

                value;
            } else {
                throw e;
            }
        }
    }
}