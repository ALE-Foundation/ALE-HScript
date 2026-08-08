package;

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
		final script = new Script('super');
		
		script.safeExecute();
		
		script.call('new');
		

		return;

		for (scr in sys.FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.') && scr.endsWith(Config.EXTENSION))
				new Script(scr.replace(Config.EXTENSION, '')).safeExecute();
		#end
	}
}