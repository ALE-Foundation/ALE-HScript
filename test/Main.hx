package;

import ale.hscript.interp.Context;
import ale.hscript.Script;
import ale.hscript.Config;

#if sys
import sys.FileSystem;
#end

using StringTools;

typedef TypedefTest = Math;

class Main
{
	public static var estaticoso = 'oso';

	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		final context = new Context();

		final a = new Script('a', context);
		a.execute();

		final b = new Script('b', context);
		b.execute();
		
		a.call('new');
	}
}