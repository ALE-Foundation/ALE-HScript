package;

import ale.hscript.Script;
import ale.hscript.Config;

#if sys
import sys.FileSystem;
#end

import ExtensibleTest;

using StringTools;

class Main
{
	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		#if sys
		var executed:Array<String> = [];

		for (scr in FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.'))
				if (scr.endsWith(Config.EXTENSION))
				{
					final name:String = scr.replace(Config.EXTENSION, '');

					if (executed.contains(name))
						continue;

					executed.push(name);

					new Script(name).safeExecute();
				}
		#end
	}

	public function typed<T>(type:T):T
		return type;
}