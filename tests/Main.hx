package;

import ale.hscript.interp.bytecode.BytecodeInterp;

import ale.hscript.Script;
import ale.hscript.Config;

using StringTools;

class Oso
{
	public var oso:String;

	public function new(str:String)
		oso = str;
}

class Main
{
	static function main()
	{
		#if cpp
		cpp.CPPCrashHandler.runCPPCrashHandler();
		#end

		#if sys
		for (scr in sys.FileSystem.readDirectory(Config.SCRIPT_PATH))
			if (!scr.startsWith('.') && scr.endsWith(Config.EXTENSION))
				new Script(scr.replace(Config.EXTENSION, ''), new BytecodeInterp()).safeExecute();
		#end
	}
}