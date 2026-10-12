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
	static var toTest:ExtensibleTest = null;

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

	static function callTest()
	{
		trace(toTest);

		trace(toTest?.osoFunc());
	}
}