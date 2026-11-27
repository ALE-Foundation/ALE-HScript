package;

import ale.hscript.bytecode.VirtualMachine;
import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

typedef Test = haxe.ds.ObjectMap<Dynamic, Dynamic>;

class Inst
{
	public function new() {}

	var donde:String = 'donde';
}

class Main
{
	static function main()
	{
		final context = new Scope();

		final scr = new Script('script', /*superInstance, context) -> new VirtualMachine(superInstance, context),*/ context, new Inst());
		scr.execute();
	}
}