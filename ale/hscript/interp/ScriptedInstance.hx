package ale.hscript.interp;

import ale.hscript.macros.ExtensibleMacro;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

#if ALE_HS_MODULES
import ale.hscript.module.ModuleClass;
#end

import ale.hscript.utils.Util;

import ale.hscript.Config;

#if ALE_HS_CLASSES
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

    public var _scriptedThis(default, set):ScriptedInstance;
    function set__scriptedThis(val:ScriptedInstance):ScriptedInstance
    {
        if (superType is ScriptedClass)
            (superInstance : ScriptedInstance)._scriptedThis = val;

        return _scriptedThis = val;
    }

    var _constructor:Constructor;
    public var nativeInstance:IExtensible;
        
    public function new(type:ScriptedClass, body:Array<Expr>, ?superType:Extensible, ?imports:Map<String, Dynamic>, ?usings:Array<Dynamic>, ?pack:String)
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

        if (imports != null)
            this.imports = imports;

        if (usings != null)
            this.usings = usings;
        
        if (pack != null)
            _package = pack;

        name = type.toString();

        if (superType is ScriptedClass)
        {
            superInstance = (superType : ScriptedClass).instance();
         
            scope = variables = new Scope(superInstance.variables);
            methods = superInstance.methods;
        }

        _this = _scriptedThis = this;

        executeBody(body);

        if (!methods.exists('toString'))
        {
            define('toString', () -> {
                _scriptedThis.allowMethodToString = false;

                final res:String = _scriptedThis.toString();

                _scriptedThis.allowMethodToString = true;

                return res;
            }, [], PDefault, PNever, true);

            methods['toString'] = variables;
        }
    }

    public function preConstructor(?args:Array<Dynamic>)
        errorHandled(() -> {
            if (_constructor == null)
                return;

            enterScope(variables);

            try
            {
                for (i => arg in _constructor.funcArgs)
                    scope.define(arg.id, args[i] ?? eval(arg.value));

                eval(_constructor.pre);
            } catch(e:Dynamic) {
                exitScope();

                throw e;
            }
        });

    public function constructorArgs():Array<Dynamic>
        return errorHandled(() -> _constructor == null ? null : evalArray(_constructor.superArgs));

    public function postConstructor()
        errorHandled(() -> {
            if (_constructor == null)
                return;

            eval(_constructor.post);

            exitScope();
        });

    public function callConstructor(?args:Array<Dynamic>):Dynamic
        return errorHandled(() -> {
            if (args != null)
            {
                _this = this;

                if (_constructor == null)
                {
                    if (superType == null)
                    {
                        final scp:Scope = variables.resolve('new');

                        if (scp == null)
                            throw EUnknownVariable('new');

                        Reflect.callMethod(null, Scope.read(scp, 'new'), args);
                    } else {
                        if (superType is ScriptedClass)
                        {
                            superInstance.callConstructor(args);

                            if (superInstance.nativeInstance != null)
                            {
                                _this = nativeInstance = superInstance.nativeInstance;

                                nativeInstance._ALE_HScript_Scripted = this;
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

            _scriptedThis = this;

            return _this;
        });

    public function executeBody(body:Array<Expr>)
        errorHandled(() -> {
            for (expr in body)
                switch ((lastExpr = expr)?.type)
                {
                    case EExtendedConstructor(pre, superArgs, post, funcArgs):
                        _constructor = new Constructor(pre, superArgs, post, funcArgs);

                        null;

                    case EVarDecl(id, _, access, _, _, _):
                        if (access != null && access.contains(TStatic))
                            continue;

                        final scp:Scope = variables.resolve(id);

                        if (scp != null)
                            throw EDuplicated(id);

                        eval(expr);

                    case EFunctionDecl(id, access, value, overr):
                        if (access != null && access.contains(TStatic))
                            continue;

                        if (methods.exists(id) && !overr)
                        {
                            throw EDuplicated(id);
                        } else {
                            final func:Dynamic = eval(value);

                            define(id, func, access, PDefault, PNever, true);

                            if (id != 'new')
                                methods[id] = scope;
                        }

                    case null, EEof:

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
                        Reflect.callMethod(nativeInstance, Reflect.getProperty(nativeInstance, id + ExtensibleMacro.SUPER_SUFFIX), resArgs);
                    else
                        throw e;
                }

            default:
                super.eval(expr);
        }

    override function scopeResolve(scp:Scope, id:String):Dynamic
        return scp.resolve(id, variables);

    override function scopeRead(scp:Scope, id:String):Dynamic
        return Scope.read(scp, id, methods['get_' + id]);

    override function postResolve(id:String):Dynamic
    {
        #if ALE_HS_MODULES
        if (type is ModuleClass)
        {
            final scp:Scope = cast(type, ModuleClass).statics.resolve(id);

            if (scp != null)
                return Scope.read(scp, id);
        }
        #end

        return get(id);
    }

    override function scopeWrite(scp:Scope, id:String, value:Dynamic):Dynamic
        return Scope.write(scp, id, value, methods['set_' + id]);

    override function postAssign(id:String, value:Dynamic):Dynamic
    {
        #if ALE_HS_MODULES
        if (type is ModuleClass)
        {
            final scp:Scope = cast(type, ModuleClass).statics.resolve(id);

            if (scp != null)
                return Scope.write(scp, id, value);
        }
        #end

        return set(id, value);
    }
    
    public function call(id:String, ?args:Array<Dynamic>):Dynamic
        return errorHandled(() -> {
            final scp:Scope = methods[id].resolve(id);

            if (scp == null)
                throw EUnknownVariable(id);

            return Reflect.callMethod(null, Scope.read(scp, id), args ?? []);
        });

    public function get(id:String, ?allowNative:Bool = true):Dynamic
    {
        final scp:Scope = variables.resolve(id);

        if (scp != null)
            return Scope.read(scp, id, methods['get_' + id]);

        if (allowNative && nativeInstance != null && nativeInstance._ALE_HScript_Fields.exists(id))
            return Reflect.getProperty(nativeInstance, id);

        throw EUnknownVariable(id);
    }

    public function set(id:String, value:Dynamic, ?allowNative:Bool = true):Dynamic
    {
        final scp:Scope = variables.resolve(id);

        if (scp != null)
            return Scope.write(scp, id, value, methods['set_' + id]);

        if (allowNative && nativeInstance != null && nativeInstance._ALE_HScript_Fields.exists(id))
        {
            Reflect.setProperty(nativeInstance, id, value);

            return value;
        }

        throw EUnknownVariable(id);
    }
}
#end