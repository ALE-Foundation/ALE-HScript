package;

@:build(ale.hscript.macros.ExtensibleMacro.build())
class ExtensibleTest
{
    var oso:String = 'tu ta';

    public function new(arg:String = 'donde')
        trace(arg);

    public function osoFunc():String
    {
        trace('donde');

        return 'oso';
    }
}