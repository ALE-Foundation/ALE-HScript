package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Test
{
	var oso:String = 'masha';

	public function new(arg)
		trace(arg);

	public function method()
	{
		trace('donde');
	}
}

class Main
{
	static function main()
	{
		final context = new Scope();

		new Script('script', context).execute();
	}
}