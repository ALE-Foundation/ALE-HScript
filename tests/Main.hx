package;

import ale.hscript.Script;
import ale.hscript.Config;

using StringTools;

class Main
{
	static function main()
	{
		#if sys
		for (scr in sys.FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (scr.endsWith(Config.EXTENSION))
				new Script(scr.replace(Config.EXTENSION, '')).execute();
		#end
	}
}
