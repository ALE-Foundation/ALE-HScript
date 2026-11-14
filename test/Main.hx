package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Oso
{
	public function new() {}

	var zoom(default, set):Float = 50;

	function set_zoom(val:Float):Float
		return zoom = val;

	@:isVar
	var donde(get, set):Float = 60;
	function get_donde():Float
		return donde;
	function set_donde(val:Float):Float
		return donde = val;

	var _tuta:Float = 0;
	var tuta(get, set):Float;
	function get_tuta():Float
		return _tuta;
	function set_tuta(val:Float):Float
		return _tuta = val;
}

class Extensible extends Oso {}

class Main
{
	static function main()
	{
		final context = new Scope();

		new Script('script', context).execute();
	}
}