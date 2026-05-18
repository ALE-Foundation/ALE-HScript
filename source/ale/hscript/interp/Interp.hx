package ale.hscript.interp;

import ale.hscript.parser.Expr;

import ale.hscript.lexer.TokenUtil;
import ale.hscript.lexer.Token;

import ale.hscript.utils.TypeList;

import ale.hscript.ScriptedClass;
import ale.hscript.Config;

import ale.hscript.classes.ScriptedInstance;

import haxe.Constraints.IMap;

import haxe.Log;

using StringTools;

class Interp
{
    public final name:String;

    public var scope:Scope;

    public var scriptPackage:String = null;

    public function new(?name:String)
    {
        this.name = name ?? Config.INTERP_NAME;

        scope = new Scope();

        scope.define('trace', (e) -> Log.trace(e, {fileName: name, lineNumber: -1, className: name.split('/').pop(), methodName: ': '}));
        scope.define('Math', Math);
    }

    public function execute(expr:Expr, ?optionalScope:Scope):Dynamic
    {
        return switch (expr)
        {
            case EProgram(stmts):
                var result = null;

                try
                {
                    for (stmt in stmts)
                        result = execute(stmt);
                } catch (signal:ReturnSignal) {
                    result = signal.value;
                }

                result;
            
            case EPackage(pack):
                scriptPackage = pack;

                null;

            case EImport(module, wildcard, nick):
                if (wildcard)
                {
                    if (TypeList.list.exists(module))
                    {
                        for (cls in TypeList.list.get(module))
                        {
                            final type = resolveClass(module + '.' + cls);

                            if (type != null)
                                scope.define(cls, type);
                        }
                    }
                } else {
                    scope.define(nick ?? module.split('.').pop(), resolveClass(module));
                }

                null;

            case ENew(type, args):
                createInstance(execute(type), [for (arg in args) execute(arg)]);

            case EBlock(stmts):
                final previous:Scope = scope;
                
                scope = optionalScope ?? new Scope(scope);

                var result = null;

                for (stmt in stmts)
                    result = execute(stmt);

                scope = previous;

                result;

            case EField(left, field):
                getProperty(left == null ? null : execute(left), field);

            case ESet(obj, value, returnNew):
                switch (obj)
                {
                    case EField(left, field):
                        setProperty(left == null ? null : execute(left), field, value, returnNew);
                    default:
                        null;
                }

            case ECall(obj, args):
                Reflect.callMethod(null, execute(obj), [for (arg in args) execute(arg)]);

            case EArrayAccess(obj, value):
                final newObj:Dynamic = execute(obj);
                
                if (newObj is Array)
                    newObj[execute(value)];
                else if (Std.isOfType(newObj, IMap))
                    cast(newObj, IMap<Dynamic, Dynamic>).get(execute(value));
                else
                    null;

            case EStruct(map):
                final result:Dynamic = {};

                for (key in map.keys())
                    Reflect.setField(result, key, execute(map[key]));

                result;

            case EVar(name, value):
                scope.define(name, execute(value));

            case EFunction(name, args, block):
                final func = Reflect.makeVarArgs(
                    (params:Array<Dynamic>) -> {
                        final newScope:Scope = new Scope(scope);

                        for (i => arg in args)
                            newScope.define(arg.name, params[i] ?? execute(arg.value));

                        final previous = scope;

                        scope = newScope;

                        var result = null;

                        try {
                            execute(block);
                        } catch (signal:ReturnSignal) {
                            result = signal.value;
                        }

                        scope = previous;

                        return result;
                    }
                );

                if (name == null)
                {
                    func;
                } else {
                    scope.define(name, func);

                    null;
                }

            case EType(module):
                resolveClass(module) ?? resolveClass((scriptPackage == null ? '' : scriptPackage + '.') + module) ?? scope.get(module);

            case EBinOp(left, op, right):
                final l:Dynamic = execute(left);

                final r:Dynamic = execute(right);

                if (l == null || r == null)
                    return null;

                untyped switch (op)
                {
                    case TPlus, TPlusEqual:
                        l + r;

                    case TStar, TStarEqual:
                        l * r;

                    case TSlash, TSlashEqual:
                        l / r;

                    case TPercent, TPercentEqual:
                        l % r;

                    case TDoubleEqual:
                        l == r;

                    case TExclamationEqual:
                        l != r;

                    case TLess:
                        l < r;

                    case TGreater:
                        l > r;

                    case TLessEqual:
                        l <= r;

                    case TGreaterEqual:
                        l >= r;

                    case TDoubleAmpersand:
                        l && r;

                    case TDoublePipe:
                        l || r;

                    case TAmpersand, TAmpersandEqual:
                        l & r;

                    case TPipe, TPipeEqual:
                        l | r;

                    case TCaret, TCaretEqual:
                        l ^ r;

                    case TDoubleLess, TDoubleLessEqual:
                        l << r;

                    case TDoubleGreater, TDoubleGreaterEqual:
                        l >> r;

                    case TTripleGreater, TTripleGreaterEqual:
                        l >>> r;

                    default:
                        null;
                }

            case EPrefix(op, right):
                final r:Dynamic = execute(right);

                if (r == null)
                    return null;

                untyped switch (op)
                {
                    case TExclamation:
                        !r;

                    case TMinus:
                        -r;

                    case TDoublePlus:
                        r + 1;
                        
                    case TDoubleMinus:
                        r - 1;

                    default:
                        null;
                }

            case EPostfix(left, op):
                final l:Dynamic = execute(left);

                if (l == null)
                    return null;

                untyped switch (op)
                {
                    case TDoublePlus:
                        l + 1;

                    case TDoubleMinus:
                        l - 1;

                    default:
                        null;
                }

            case ETernOp(condition, trueCase, falseCase):
                if (execute(condition))
                    execute(trueCase);
                else
                    execute(falseCase);

            case ENull:
                null;

            case ETrue:
                true;

            case EFalse:
                false;

            case ENumber(value):
                value;

            case EString(value):
                value;

            case EArray(values):
                [for (val in values) execute(val)];

            case EMap(value):
                final result:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();

                for (key in value.keys())
                    result.set(execute(key), execute(value[key]));

                result;

            case EReturn(value):
                throw new ReturnSignal(execute(value));

            default:
                null;
        }
    }

    function setProperty(obj:Dynamic, field:String, value:Expr, ?returnNew:Bool = true):Dynamic
    {
        final oldValue:Dynamic = getProperty(obj, field);

        final newValue:Dynamic = execute(value);

        if (obj == null)
            scope.set(field, newValue);
        else if (obj is ScriptedInstance)
            obj.interp.scope.set(field, newValue);
        else
            Reflect.setProperty(obj, field, newValue);

        return returnNew ? newValue : oldValue;
    }

    function getProperty(obj:Dynamic, field:String):Dynamic
    {
        if (obj == null)
            return scope.get(field);

        if (obj is ScriptedInstance)
            return obj.interp.scope.get(field);

        return Reflect.getProperty(obj, field);
    }

    function resolveClass(path:String):Dynamic
    {
        if (Config.FILE_CHECKER(Config.MODULE_PATH + path.replace('.', '/') + Config.MODULE_EXTENSION))
            return new ScriptedClass(path);

        return Type.resolveClass(path);
    }

    function createInstance(cls:Dynamic, ?args:Array<Dynamic>):Dynamic
    {
        args ??= [];

        if (cls is ScriptedClass)
            return cls.instantiate(args);

        return cls is Class ? Type.createInstance(cls, args) : null;
    }
}