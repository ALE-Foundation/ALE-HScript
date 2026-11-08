package;

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
				if (scr.endsWith(Config.SCRIPT_EXTENSION))
					new Script(scr.replace(Config.SCRIPT_EXTENSION, '')).safeExecute();
		#end
	}
}