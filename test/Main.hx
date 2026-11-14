package;

import ale.hscript.interp.Scope;
import ale.hscript.Script;
import ale.hscript.Config;

class Oso
{
    public var nativeValue:Int = 10;
    public var nativeCalls:Int = 0;
    public var nativeLabel:String = "default";

    public function new()
    {
        nativeCalls++;
    }

    public function nativeMethod(value:Int):Int
    {
        return nativeValue + value;
    }

    public function nativeToString():String
    {
        return nativeLabel + ":" + nativeValue;
    }
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