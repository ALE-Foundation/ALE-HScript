package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class MyClass
{
	public function new() {}

	public function oso()
		trace('oso');
}

class Penecio<A:MyClass>
{
	public function new() {}

	var oso:String = 'donde';

	public function a(arg:A):A
		return null;
}

class Donde<B> extends Penecio<MyClass>
{
	public function b(arg:B):B
		return null;
}

class Extensible<C:MyClass> extends Donde<Penecio<MyClass>>
{
	public function c(arg:C):C
		return null;
}

class Main
{
	static function main()
	{
		final context = new Scope();

		final scr = new Script('script', context, new Extensible());
		scr.execute();
	}
}