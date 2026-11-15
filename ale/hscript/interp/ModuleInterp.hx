package ale.hscript.interp;

import ale.hscript.errors.ErrorType;

import ale.hscript.parser.Expr;

class ModuleInterp extends Interp
{
    final expectedPackage:String;
    final types:Array<Expr> = [];

    public function new(expectedPackage:String, types:Array<Expr>)
    {
        super();

        this.expectedPackage = expectedPackage;
        this.types = types;
    }

    public function executeModule():Array<ModuleType>
    {
        final result:Array<ModuleType> = [];

        errorHandled(() -> {
            for (expr in types)
            {
                final res:ModuleType = evalModule(expr);
                
                if (res != null)
                    result.push(res);
            }
        });

        return result;
    }

    function evalModule(expr:Expr):ModuleType
        return switch ((lastExpr = expr)?.type)
        {
            case EImport(_), EUsing(_), ETypedef(_, _), EInterfaceDecl(_, _):
                eval(expr);
            
                null;
         
            case EPackage(mod):
                if (expectedPackage != mod)
                    throw EInvalidPackage(mod, expectedPackage);
                else
                    eval(expr);

                null;
                
            case EClassDecl(id, body, parent, implem):
                final cls:ScriptedClass = new ScriptedClass(id, body, eval(parent), imports, usings);

                imports[id] = cls;

                {
                    id: id,
                    value: cls
                }

            case EAlias(id, type):
                final ty:Dynamic = eval(type);

                imports[id] = ty;
                
                {
                    id: id,
                    value: ty
                }

            case EEof, null:
                null;

            default:
                throw EInvalidExpression(expr.type);
        }
}