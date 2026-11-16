package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Typed<T>
{
	public function new() {}

	public function oso()
		return 'donde';
}

class Main
{
	static function main()
	{
		final context = new Scope();

		final scr = new Script('script', context);
		scr.execute();

		scr.call('new');
	}
}