package ale.hscript.utils;

import ale.hscript.Config;

class Util
{
    public static function resolveScript(script:String, ?name:String):SourceData
    {
        final path:String = Config.SCRIPT_PATH + script + Config.EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        final baseName:String = name ?? (isFile ? script : Config.SCRIPT_NAME);

        return {
            source: isFile ? Config.FILE_READER(path) : script,
            name: baseName + Config.EXTENSION,
            compiledPath: Config.SCRIPT_PATH + (isFile ? script : name ?? Config.SCRIPT_NAME) + Config.COMPILED_EXTENSION
        };
    }
}