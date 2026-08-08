package;

import ale.hscript.Script;
import ale.hscript.Config;

using StringTools;

class Oso
{
	public var oso:String = 'donde';

	public function new() {}
}

class Main
{
	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		#if sys
		for (scr in sys.FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.') && scr.endsWith(Config.EXTENSION))
				new Script(scr.replace(Config.EXTENSION, ''), null, new Oso()).safeExecute();
		#end
	}
}