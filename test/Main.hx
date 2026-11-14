package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class PutoAccessor
{
    public function new() {}

    var zoom(default, set):Float = 0;

    function set_zoom(val:Float):Float
    {
        trace('super oso');

        return val;
    }

    function update()
    {
        trace(zoom = 67);
    }
}

class Extensible extends PutoAccessor {}

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