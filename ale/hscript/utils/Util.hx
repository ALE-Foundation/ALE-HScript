package ale.hscript.utils;

import ale.hscript.serialization.Unserializer;

import ale.hscript.Config;

class Util
{
    public static function resolveSourceData(script:String, ?name:String):SourceData
    {
        final basePath:String = Config.SCRIPT_PATH + script;

        final path:String = basePath + Config.EXTENSION;
        final compiledPath:String = basePath + Config.COMPILED_EXTENSION;

        final isFile:Bool = Config.FILE_CHECKER != null && Config.FILE_CHECKER(path);

        final baseName:String = name ?? (isFile ? script : Config.SCRIPT_NAME);

        return {
            source: isFile ? Config.CONTENT_READER(path) : script,
            code: Config.FILE_CHECKER(compiledPath) ? new Unserializer(script).unserialize() : null,
            name: baseName + Config.EXTENSION,
            compiledPath: Config.SCRIPT_PATH + (isFile ? script : name ?? Config.SCRIPT_NAME) + Config.COMPILED_EXTENSION
        };
    }
}