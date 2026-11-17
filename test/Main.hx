package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Main
{
	static function main()
	{
		final context = new Scope();

		final scr = new Script('script', context);
		scr.execute();
	}
}