package ale.hscript.module;

import ale.hscript.interp.ScriptedClass;
import ale.hscript.interp.Extensible;

import ale.hscript.parser.Expr;

import ale.hscript.Config;

#if ALE_HS_MODULES
class ModuleClass extends ScriptedClass
{
    public final statics:StaticsInterp;

    public function new(id:String, body:Array<Expr>, ?parent:Extensible, ?imports:Map<String, Dynamic>, ?usings:Array<Dynamic>)
    {
        super(id, body, parent, imports, usings);

        try
        {
            statics = new StaticsInterp(this, body, imports, usings);
        } catch(error:Dynamic) {
            if (Config.HANDLE_ERRORS)
                Config.ERROR_HANDLER(id, error);
            else
                throw error;
        }
    }
}
#end