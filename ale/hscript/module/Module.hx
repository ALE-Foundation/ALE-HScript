package ale.hscript.module;

import ale.hscript.interp.ScriptedClass;

import ale.hscript.lexer.Lexer;

import ale.hscript.Config;

using StringTools;

#if ALE_HS_MODULES
@:publicFields
class Module
{
    static var cache:Map<String, ModuleCache> = [];

    static function check(module:String, ?alias:String):Null<Array<ModuleType>>
    {
        final path:String = Config.MODULE_PATH + module.replace('.', '/') + Config.MODULE_EXTENSION;

        if (Config.FILE_CHECKER != null && !Config.FILE_CHECKER(path))
            return null;
        
        if (Config.MODULE_IMPORT_CALLBACK != null)
            Config.MODULE_IMPORT_CALLBACK(path);
        
        if (cache.exists(module))
        {
            final data:ModuleCache = cache[module];

            if (data.path == path)
                if (Config.FILE_TIME == null || data.time == Config.FILE_TIME(path))
                    return data.module;
        }

        final mod:Array<String> = module.split('.');

        final modId:String = mod.pop();

        var result:Array<ModuleType> = null;

        try
        {
            result = new ModuleInterp(mod.join('.'), new ModuleParser(new Lexer(Config.FILE_READER(path)).tokenize()).parseModule()).executeModule();
        } catch(error:Dynamic) {
            if (Config.HANDLE_ERRORS)
                Config.ERROR_HANDLER(module, error);
            else
                throw error;
        }

        if (result != null)
            cache[module] = {
                module: result,
                path: path,
                time: Config.FILE_TIME == null ? -1 : Config.FILE_TIME(path)
            };

        for (type in result)
            if (type.id == modId && alias != null)
                type.id = alias;

        return result;
    }

    static function reset()
        cache = [];
}
#end