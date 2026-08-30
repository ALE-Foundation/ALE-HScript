package;

import ale.hscript.interp.BytecodeInterp;

import ale.hscript.serialization.Serializer;

import ale.hscript.Script;
import ale.hscript.Config;

#if sys
import sys.FileSystem;
#end

using StringTools;

class Main
{
	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		#if sys
		for (scr in FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.'))
				if (scr.endsWith(Config.EXTENSION))
				{
					final name:String = scr.replace(Config.EXTENSION, '');

					if (FileSystem.exists(Config.SCRIPT_PATH + name + Config.COMPILED_EXTENSION))
						continue;

					new Serializer(name).save();

					new Script(name).safeExecute();
				} else if (scr.endsWith(Config.COMPILED_EXTENSION)) {
					new Script(scr.replace(Config.COMPILED_EXTENSION, '')).safeExecute();
				}
		#end
	}
}