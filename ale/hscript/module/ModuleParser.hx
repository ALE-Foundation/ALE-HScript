package ale.hscript.module;

import ale.hscript.interp.ScriptedClass;

import ale.hscript.parser.Parser;
import ale.hscript.parser.Expr;

import ale.hscript.lexer.Token;

class ModuleParser extends Parser
{
    public function parseModule():Array<Expr>
    {
        final result:Array<Expr> = [];

        while (index < length)
        {
            final res:Expr = parseModuleStatement();
            
            if (res != null)
                result.push(res);
        }

        return result;
    }

    function parseModuleStatement():Expr
    {
        final cur:Token = peek();

        final res:Expr = switch (cur.type)
        {
            case TPackage, TImport, TUsing, TTypedef, TClass, TInterface, TEof:
                parseStatement();

            default:
                error(EUnexpected(cur.type), cur);

                null;
        }

        if (res != null)
            semicolon(res.type);

        return res;
    }
}