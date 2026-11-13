package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Test
{
	@:isVar
	var oso(get, set):Float = -1;

	function get_oso():Float
		return oso;

	function set_oso(val:Float):Float
		return oso = val;

	public function new() {}
}

class Main
{
	static function main()
	{
		final context = new Scope();

		new Script('script', context).execute();
	}
}