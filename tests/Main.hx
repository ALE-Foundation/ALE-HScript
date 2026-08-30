package;

import ale.hscript.interp.BytecodeInterp;

import ale.hscript.serialization.Serializer;

import ale.hscript.Script;
import ale.hscript.Config;

using StringTools;

class Main
{
	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		#if sys
		for (scr in sys.FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.'))
				if (scr.endsWith(Config.EXTENSION))
				{
					final name:String = scr.replace(Config.EXTENSION, '');
					
					new Serializer(name).save();

					new Script(name).safeExecute();
				} else if (scr.endsWith(Config.COMPILED_EXTENSION)) {
					new Script(scr.replace(Config.COMPILED_EXTENSION, '')).execute();
				}
		#end
	}
}