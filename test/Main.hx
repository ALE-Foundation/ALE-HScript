package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Child
{
	public function new() {}

    function test(_:TransformType):Void {}
}

private enum TransformType {}


class Main
{
	static function main()
	{
		final context = new Scope();

		new Script('script', context).execute();
	}
}