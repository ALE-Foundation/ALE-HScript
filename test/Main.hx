package;

import ale.hscript.interp.Context;
import ale.hscript.Script;
import ale.hscript.Config;

class Main
{
	public static var estaticoso = 'oso';

	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		final context = new Context();

		new Script('script', context).execute();
	}
}