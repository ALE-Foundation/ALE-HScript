package;

import ale.hscript.bytecode.VirtualMachine;
import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Main
{
	static function main()
	{
		final scr = new Script('script');
		scr.execute();
	}
}